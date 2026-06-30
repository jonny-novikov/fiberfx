import {
  PHX_DONE_REFS,
  PHX_PREFLIGHTED_REFS,
  PHX_UPLOAD_REF,
} from "./constants";

import {} from "./utils";

import DOM from "./dom";
import UploadEntry from "./upload_entry";

import type View from "./view";
import type LiveSocket from "./live_socket";

// The per-file payload serialized for the preflight request. `path` is set at
// construction; the rest are filled in field-by-field, and `meta` is the
// opaque value returned by a file's optional meta() hook.
interface SerializedUploadEntry {
  path: string;
  ref?: string;
  last_modified?: number;
  name?: string;
  relative_path?: string;
  type?: string;
  size?: number;
  meta?: unknown;
}

let liveUploaderFileRef = 0;

export default class LiveUploader {
  autoUpload: boolean;
  view: View;
  onComplete: () => void;
  _entries: UploadEntry[];
  numEntriesInProgress: number;

  static genFileRef(file: LiveViewFile): string {
    const ref = file._phxRef;
    if (ref !== undefined) {
      return ref;
    } else {
      file._phxRef = (liveUploaderFileRef++).toString();
      return file._phxRef;
    }
  }

  static getEntryDataURL(inputEl: HTMLElement, ref: string) {
    const file = this.activeFiles(inputEl).find(
      (file: LiveViewFile) => this.genFileRef(file) === ref,
    );
    if (!file) return null;
    return URL.createObjectURL(file);
  }

  static hasUploadsInProgress(formEl: HTMLElement) {
    let active = 0;
    DOM.findUploadInputs(formEl).forEach((input: HTMLElement) => {
      if (
        input.getAttribute(PHX_PREFLIGHTED_REFS) !==
        input.getAttribute(PHX_DONE_REFS)
      ) {
        active++;
      }
    });
    return active > 0;
  }

  static serializeUploads(inputEl: HTMLInputElement) {
    const files = this.activeFiles(inputEl);
    const fileData: { [ref: string]: SerializedUploadEntry[] } = {};
    files.forEach((file: LiveViewFile) => {
      const entry: SerializedUploadEntry = { path: inputEl.name };
      const uploadRef = inputEl.getAttribute(PHX_UPLOAD_REF)!;
      fileData[uploadRef] = fileData[uploadRef] || [];
      entry.ref = this.genFileRef(file);
      entry.last_modified = file.lastModified;
      entry.name = file.name || entry.ref;
      entry.relative_path = file.webkitRelativePath;
      entry.type = file.type;
      entry.size = file.size;
      if (typeof file.meta === "function") {
        entry.meta = file.meta();
      }
      fileData[uploadRef].push(entry);
    });
    return fileData;
  }

  static clearFiles(inputEl: HTMLInputElement) {
    // runtime-neutral: upstream assigns null; cast keeps the exact runtime value
    inputEl.value = null as unknown as string;
    inputEl.removeAttribute(PHX_UPLOAD_REF);
    DOM.putPrivate(inputEl, "files", []);
  }

  static untrackFile(inputEl: HTMLInputElement, file: LiveViewFile) {
    DOM.putPrivate(
      inputEl,
      "files",
      DOM.private(inputEl, "files").filter((f: LiveViewFile) => !Object.is(f, file)),
    );
  }

  static trackFiles(
    inputEl: HTMLInputElement,
    files: LiveViewFile[],
    dataTransfer?: DataTransfer,
  ) {
    if (inputEl.getAttribute("multiple") !== null) {
      const newFiles = files.filter(
        (file) =>
          !this.activeFiles(inputEl).find((f: LiveViewFile) =>
            Object.is(f, file),
          ),
      );
      DOM.updatePrivate(inputEl, "files", [], (existing: LiveViewFile[]) =>
        existing.concat(newFiles),
      );
      inputEl.value = "";
    } else {
      // Reset inputEl files to align output with programmatic changes (i.e. drag and drop)
      if (dataTransfer && dataTransfer.files.length > 0) {
        inputEl.files = dataTransfer.files;
      }
      DOM.putPrivate(inputEl, "files", files);
    }
  }

  static activeFileInputs(formEl: HTMLElement) {
    const fileInputs = DOM.findUploadInputs(formEl);
    return Array.from(fileInputs).filter(
      (el: HTMLInputElement) => el.files && this.activeFiles(el).length > 0,
    );
  }

  static activeFiles(input: HTMLElement): LiveViewFile[] {
    return (DOM.private(input, "files") || []).filter((f: LiveViewFile) =>
      UploadEntry.isActive(input as HTMLInputElement, f),
    );
  }

  static inputsAwaitingPreflight(formEl: HTMLElement) {
    const fileInputs = DOM.findUploadInputs(formEl);
    return Array.from(fileInputs).filter(
      (input: HTMLElement) => this.filesAwaitingPreflight(input).length > 0,
    );
  }

  static filesAwaitingPreflight(input: HTMLElement) {
    return this.activeFiles(input).filter(
      (f: LiveViewFile) =>
        !UploadEntry.isPreflighted(input as HTMLInputElement, f) &&
        !UploadEntry.isPreflightInProgress(f),
    );
  }

  static markPreflightInProgress(entries: UploadEntry[]) {
    entries.forEach((entry) => UploadEntry.markPreflightInProgress(entry.file));
  }

  constructor(inputEl: HTMLInputElement, view: View, onComplete: () => void) {
    this.autoUpload = DOM.isAutoUpload(inputEl);
    this.view = view;
    this.onComplete = onComplete;
    this._entries = Array.from(
      LiveUploader.filesAwaitingPreflight(inputEl) || [],
    ).map((file) => new UploadEntry(inputEl, file, view, this.autoUpload));

    // prevent sending duplicate preflight requests
    LiveUploader.markPreflightInProgress(this._entries);

    this.numEntriesInProgress = this._entries.length;
  }

  isAutoUpload() {
    return this.autoUpload;
  }

  entries() {
    return this._entries;
  }

  initAdapterUpload(
    // resp is the opaque preflight response forwarded to each entry + uploader.
    resp: any,
    // onError is the uploader-protocol error callback; its args are app-defined.
    onError: (...args: any[]) => void,
    liveSocket: LiveSocket,
  ) {
    this._entries = this._entries.map((entry) => {
      if (entry.isCancelled()) {
        this.numEntriesInProgress--;
        if (this.numEntriesInProgress === 0) {
          this.onComplete();
        }
      } else {
        entry.zipPostFlight(resp);
        entry.onDone(() => {
          this.numEntriesInProgress--;
          if (this.numEntriesInProgress === 0) {
            this.onComplete();
          }
        });
      }
      return entry;
    });

    const groupedEntries = this._entries.reduce(
      // callback is the host-supplied uploader (or channelUploader); its shape
      // is app-defined, so it stays `any`.
      (
        acc: { [name: string]: { callback: any; entries: UploadEntry[] } },
        entry,
      ) => {
        if (!entry.meta) {
          return acc;
        }
        const { name, callback } = entry.uploader(liveSocket.uploaders);
        acc[name] = acc[name] || { callback: callback, entries: [] };
        acc[name].entries.push(entry);
        return acc;
      },
      {},
    );

    for (const name in groupedEntries) {
      const { callback, entries } = groupedEntries[name];
      callback(entries, onError, resp, liveSocket);
    }
  }
}

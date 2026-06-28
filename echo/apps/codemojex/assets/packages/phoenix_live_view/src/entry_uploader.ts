import { logError } from "./utils";

import type { Channel } from "phoenix";
import type LiveSocket from "./live_socket";
import type UploadEntry from "./upload_entry";

interface EntryUploaderConfig {
  chunk_size: number;
  chunk_timeout: number;
}

export default class EntryUploader {
  liveSocket: LiveSocket;
  entry: UploadEntry;
  offset: number;
  chunkSize: number;
  chunkTimeout: number;
  chunkTimer: ReturnType<typeof setTimeout> | null;
  errored: boolean;
  uploadChannel: Channel;

  constructor(
    entry: UploadEntry,
    config: EntryUploaderConfig,
    liveSocket: LiveSocket,
  ) {
    const { chunk_size, chunk_timeout } = config;
    this.liveSocket = liveSocket;
    this.entry = entry;
    this.offset = 0;
    this.chunkSize = chunk_size;
    this.chunkTimeout = chunk_timeout;
    this.chunkTimer = null;
    this.errored = false;
    this.uploadChannel = liveSocket.channel(`lvu:${entry.ref}`, {
      token: entry.metadata(),
    });
  }

  error(reason?: unknown) {
    if (this.errored) {
      return;
    }
    this.uploadChannel.leave();
    this.errored = true;
    this.chunkTimer != null && clearTimeout(this.chunkTimer);
    this.entry.error(reason);
  }

  upload() {
    this.uploadChannel.onError((reason?: unknown) => this.error(reason));
    this.uploadChannel
      .join()
      .receive("ok", (_data?: unknown) => this.readNextChunk())
      // server error payload is opaque wire JSON
      .receive("error", ({ reason }: { reason?: unknown }) =>
        this.error(reason),
      );
  }

  isDone() {
    return this.offset >= this.entry.file.size;
  }

  readNextChunk() {
    const reader = new window.FileReader();
    const blob = this.entry.file.slice(
      this.offset,
      this.chunkSize + this.offset,
    );
    reader.onload = (e) => {
      if (e.target?.error === null) {
        this.offset += (e.target.result as ArrayBuffer).byteLength;
        this.pushChunk(e.target.result as ArrayBuffer);
      } else {
        return logError("Read error: " + e.target?.error);
      }
    };
    reader.readAsArrayBuffer(blob);
  }

  pushChunk(chunk: ArrayBuffer) {
    if (!this.uploadChannel.isJoined()) {
      return;
    }
    this.uploadChannel
      .push("chunk", chunk, this.chunkTimeout)
      .receive("ok", () => {
        this.entry.progress((this.offset / this.entry.file.size) * 100);
        if (!this.isDone()) {
          this.chunkTimer = setTimeout(
            () => this.readNextChunk(),
            this.liveSocket.getLatencySim() || 0,
          );
        }
      })
      // server error payload is opaque wire JSON
      .receive("error", ({ reason }: { reason?: unknown }) =>
        this.error(reason),
      );
  }
}

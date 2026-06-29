import EntryUploader from "phoenix_live_view/entry_uploader";
import type UploadEntry from "phoenix_live_view/upload_entry";
import type LiveSocket from "phoenix_live_view/live_socket";

describe("EntryUploader", () => {
  test("passes channel-error reply reason as string to entry.error", () => {
    let errorCb;
    let fakeChannel = {
      onError: vi.fn(),
      leave: vi.fn(),
      join: () => ({
        receive(kind, cb) {
          if (kind === "error") errorCb = cb;
          return this;
        },
      }),
    };
    let fakeLiveSocket = { channel: () => fakeChannel } as unknown as LiveSocket;
    let entry = {
      ref: "0",
      metadata: () => ({}),
      error: vi.fn(),
    } as unknown as UploadEntry;
    let config = { chunk_size: 1024, chunk_timeout: 5000 };

    new EntryUploader(entry, config, fakeLiveSocket).upload();

    // Reply payload arrives as {reason: "..."}, not as a string.
    errorCb({ reason: "join crashed" });

    expect(entry.error).toHaveBeenCalledWith("join crashed");
  });
});

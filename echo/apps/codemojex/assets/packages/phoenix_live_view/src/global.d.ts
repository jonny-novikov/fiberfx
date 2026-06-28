declare let LV_VSN: string;

/**
 * A browser `File`/`Blob` carrying the LiveView uploader's private bookkeeping
 * fields. These are tacked onto the native object at runtime by `LiveUploader`
 * and `UploadEntry`; declared here (ambient) so the whole package can refer to
 * the augmented shape without importing.
 */
interface LiveViewFile extends File {
  _phxRef?: string;
  _preflightInProgress?: boolean;
  meta?: () => unknown;
}

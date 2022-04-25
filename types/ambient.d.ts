// https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API/Structured_clone_algorithm#supported_types
declare type Postable =
  null | undefined | Number | BigInt | Boolean | String |
  Date | RegExp |
  Blob | File | FileList | ArrayBuffer | ArrayBufferView |
  ImageBitmap | ImageData |
  Array<Postable> | { [key: string]: Postable } | Map<Postable, Postable> | Set<Postable>

// TODO: move these somewhere?

// System launch options
declare interface LaunchOpts {
  debug?: boolean
  logger?: Logger
}

declare interface SystemConfig {

}

declare interface Logger {
  log(...data: any[]): void;
  info(...data: any[]): void;
  debug(...data: any[]): void;
  error(...data: any[]): void;
  warn(...data: any[]): void;
}

declare interface Package {
  config: {
    name?: string
  }
  source?: {
    [key: string]: {
      content: string
    }
  }
  distribution: {
    [key: string]: {
      content: string
    }
  }
  dependencies: {
    [key: string]: Package
  }
}

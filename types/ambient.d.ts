// TODO: move these somewhere?

// https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API/Structured_clone_algorithm#supported_types
declare type Postable =
  null | undefined | Number | BigInt | Boolean | String |
  Date | RegExp |
  Blob | File | FileList | ArrayBuffer | ArrayBufferView |
  ImageBitmap | ImageData |
  Array<Postable> | { [key: string]: Postable } | Map<Postable, Postable> | Set<Postable>

// TODO: Export this from observable package?
// Basic Observable
interface Observable<T> {
  (): T;
  (newValue: T): T;
  _value: T;
  observe: (fn: (x: T) => void) => void;
}

// Utility types

declare type ValueOrReturnValue<T> = T extends (...args: any[]) => any ? ReturnType<T> : T

// App Types

declare interface SystemHost {
  readFile(path: string): Promise<Blob>
  writeFile(path: string, blob: Blob): Promise<unknown>
}

declare interface SystemApplication {
  delegate: App
  title(title?: string): unknown
  icon(icon?: string): unknown
  saved(saved?: boolean): unknown

  exit(): Promise<unknown>
}

declare interface AppConfig {
  baseStyle?: boolean
}

declare interface AppClient {
  newFile(): Promise<unknown>
  loadFile(file: Blob, path: string): Promise<unknown>
  saveData(): Promise<Blob>
}

declare interface AppMethods {
  confirmUnsaved(): Promise<void>
  exit(): Promise<unknown>
  extend<T extends {}>(source: T): App & T

  drop(files: File[] | FileList): boolean
  paste(files: File[] | FileList): boolean

  /** Restore app to its blank or "new" state. */
  new: () => Promise<unknown> // Note: this needs to be written in property form because `new()` has special meaning as constructable via `new` operator.
  open(): Promise<unknown>
  save(): Promise<unknown>
  saveAs(): Promise<unknown>

  reloadStyle(cssText: string): unknown
}

declare interface App extends AppClient, AppMethods, Bindable<App> {
  config: AppConfig
  currentPath: Observable<string>
  saved: Observable<boolean>

  T: any
  pkg: Package
  version: string
  element?: HTMLElement
  icon?: string | (() => string)
  menu?: string
  style?: string
  title?: string | (() => string)
  template?: string
}

declare interface Bindable<T> {
  on(event: "*", handler: (this: T, event: string, ...args: any[]) => any): T
  on(event: string, handler: (this: T, ...args: any[]) => any): T
  off(event: string, handler?: Function): T
  trigger(event: string, ...parameters: any[]): T
}

declare interface FileEntry {
  path: string
  relativePath: string
  type: string
  size?: number
}

declare interface FolderEntry {
  path: string
  relativePath: string
  folder: true
}

declare interface MountFS {
  clearCache: () => void
  mount(folderPath: string, subsystem: ZOSFileSystem): ZOSFileSystem & MountFS
}

declare interface FSOperations {
  read(path: string): Promise<Blob | undefined>;
  write(path: string, blob: Blob, options?: any): Promise<unknown>;
  delete(path: string): Promise<unknown>;
  list(dir: string): Promise<(FileEntry | FolderEntry)[]>;
}

declare interface ZOSFileSystem extends FSOperations, Bindable<ZOSFileSystem> { }

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
    cognito?: {
      identityPoolId: string
      poolData: PoolData
    }
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

declare var PACKAGE: Package
declare var AWS: AWSInterface
declare var AWSCognito: AWSCognitoInterface

// AWS Stubs

declare interface PoolData {
  UserPoolId: string
  ClientId: string
}

declare interface UserAttribute { }

declare interface AuthenticationDetails { }

declare interface AuthenticationData {
  Username: string
  Password: string
}

declare interface AWSCognitoInterface {
  CognitoIdentityServiceProvider: {
    AuthenticationDetails: {
      new(data: AuthenticationData): AuthenticationDetails
    }
    CognitoUser: {
      new(data: any): CognitoUser
    }
    CognitoUserAttribute: {
      new(attribute: {
        Name: string
        Value: string | undefined
      }): UserAttribute
    }
    CognitoUserPool: {
      new(data: PoolData): UserPool
    }
  }
}

declare interface CognitoUser {
  authenticateUser: (details: AuthenticationDetails, cb: {
    onSuccess: (session: any) => void
    onFailure: (err: Error) => void
  }) => void
  getSession: (cb: (err: Error, result: any) => void) => void
}

declare interface UserPool {
  signUp: (username: string, password: string, attributeList: any[] | undefined, _: any, cb: (err: Error, result: any) => void) => void
  getCurrentUser: () => CognitoUser | undefined
}

declare interface AWSCredentials {
  identityId: string
  params: any
  refresh: (cb: (error: Error) => void) => void
}

declare interface AWSInterface {
  config: {
    credentials: AWSCredentials
    region?: string
  }
  S3: any
  CognitoIdentityCredentials: {
    new(data: {
      IdentityPoolId: string
      Logins: any
    }): AWSCredentials
  }
}

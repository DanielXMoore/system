// TODO: move these somewhere?

// https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API/Structured_clone_algorithm#supported_types
declare type Postable =
  null | undefined | Number | BigInt | Boolean | String |
  Date | RegExp |
  Blob | File | FileList | ArrayBuffer | ArrayBufferView |
  ImageBitmap | ImageData |
  Array<Postable> | { [key: string]: Postable } | Map<Postable, Postable> | Set<Postable>

declare interface Bindable {
  on(event: "*", handler: (event: string, ...args: any[]) => any): this
  on(event: string, handler: (...args: any[]) => any): this
  off(event: string, handler?: Function): this
  trigger(event: string, ...parameters: any[]): this
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

declare interface ZOSFileSystem extends FSOperations, Bindable { }

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

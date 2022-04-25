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

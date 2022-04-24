export interface Options {
  logger?: any
  remoteTarget?: () => typeof self | undefined
  receiver?: any
  ackTimeout?: () => number
  delegate?: any
  targetOrigin?: string
  token?: string
}

export interface Message {
  type: "message"
  method: string
  params: Postable[]
  id: number
}

export interface Ack {
  type: "ack"
  id: number
}

export interface Response {
  type: "response"
  id: number
  result: Postable
}

export interface Error {
  type: "error"
  id: number
  error: PostableError
}

export interface PostableError {
  message: string
  stack?: string
}

export type Transmission = (Message | Ack | Response | Error) & {
  from?: string
  token?: string
}

export interface PendingResponse {
  timeout: number
  ack?: true
  resolve: (result: Postable) => void
  reject: (error: PostableError) => void
}

export type EVSource = Window | MessagePort | ServiceWorker | undefined

export interface PostmasterEvent extends Event {
  data: Transmission
  source: EVSource
}

/**
Postmaster wraps the `postMessage` API with promises.

@example
```coffee
p = Postmaster
  remoteTarget: ->
    iframe.contentWindow

p.send "init"
```
*/

export interface Postmaster extends Options {
  dispose: () => void
  send: (method: string, ...params: Postable[]) => Promise<any>
  /** @deprecated */
  invokeRemote: (method: string, ...params: Postable[]) => Promise<any>

  ackTimeout: NonNullable<Options["ackTimeout"]>
  remoteTarget: NonNullable<Options["remoteTarget"]>
  targetOrigin: NonNullable<Options["targetOrigin"]>
}

export interface Constructor {
  /**
   * Construct a postmaster.
   */
  (self?: Postmaster): Postmaster
  /**
   *  The parent window or worker context that we receive messages from.
   */
  dominant: () => typeof self | undefined
}

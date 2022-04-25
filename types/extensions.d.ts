// Extensions

interface Blob {
  dataURL: () => Promise<string>
  download: (path: string) => void
  json: () => Promise<object>
}

interface JSON {
  toBlob(object: object, mime: string): Blob
}

interface HTMLCollection {
  forEach: Array<Element>['forEach']
}

interface FileList {
  forEach: Array<File>['forEach']
}

// TODO: This doesn't appear to work
declare interface Image {
  fromBlob(blob: Blob): Promise<HTMLImageElement>
}

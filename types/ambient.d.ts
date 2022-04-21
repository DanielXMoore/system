// TODO: This will be in Jadelet soon
declare module "jadelet/esbuild-plugin" {
  function _exports(options?: {}): {
    name: "jadelet";
    setup: (build: any) => any;
  };
  export = _exports;
}

declare namespace Stylus {
  type RenderOptions = import("stylus").RenderOptions

  // TODO: This doesn't seem to be extending stylus yet...
  interface Static {
    yolo: "hi"
    render(str: string, options: RenderOptions): string
  }
}

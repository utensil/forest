// follows https://gitlab.com/unconed/use.gpu/-/blob/master/packages/wgsl-loader/src/webpack.ts and https://bun.sh/docs/runtime/plugins#loaders
import { plugin } from "bun";
await plugin({
  name: "WGSL",
  async setup(build) {
    const { transpileWGSL } = await import("@use-gpu/shader/wgsl");

    // when a .wgsl file is imported...
    build.onLoad({ filter: /\.(wgsl)$/ }, async (args) => {
      // read and parse the file
      const source = await Bun.file(args.path).text();
      const exports = transpileWGSL(source, args.path).output;

      // and returns it as a module
      return {
        exports,
        loader: "object", // special loader for JS objects
      };
    });
  },
});
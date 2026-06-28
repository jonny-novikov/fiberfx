// `@mercury/ui` is resolved from source for typechecking (see tsconfig paths),
// and its entry side-effect-imports a stylesheet. Declare `*.css` so that import
// resolves under this package's program too.
declare module "*.css";

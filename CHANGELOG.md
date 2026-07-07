# Changelog

## 0.0.2 (2026-07-07)

- Require Lexxy 0.9.23+ and read Lexical primitives from its re-exported
  `Lexical` namespace instead of importing the `lexical` package directly, so
  the extension always shares the editor's Lexical instance.
- Drop the `lexical` peer dependency.
- Add importmap support: the engine now pins `@37signals/lexxy` (to the same
  `lexxy.js` the lexxy gem serves) alongside `lexxy-variables`, so importmap
  hosts need no JS tooling.

## 0.0.1

Initial release.

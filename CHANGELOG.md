# Changelog

## 0.0.3 (2026-07-13)

- Drop the local `replaceTextBackUntil` workaround for the double `{{` prompt
  bug now that the fix (basecamp/lexxy#1179) ships in Lexxy 0.9.24.
- Require Lexxy 0.9.24+ (Gemfile constraint and the `@37signals/lexxy` peer
  dependency).

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

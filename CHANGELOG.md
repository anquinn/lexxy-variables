# Changelog

## 1.0.0

- Require Lexxy 1.0+ (README, Gemfile constraint and the `@37signals/lexxy`
  peer dependency). The variables toolbar menu now works from the keyboard:
  opening it focuses the first variable, arrow keys move between variables,
  Enter inserts, and Escape closes it and returns focus to the button.
- The stylesheet is now built on Lexxy's `--lexxy-*` variables, so chips, the
  toolbar dropdown and the `{{` prompt follow your Lexxy theme, dark themes
  included. Set any Lexxy variable on one of the gem's classes to change just
  that piece. The README lists each class and the Lexxy variables it uses.
- **Visual change:** chips default to Lexxy's selection color
  (`--lexxy-color-selected`) instead of indigo. Set
  `--lexxy-variable-background` and `--lexxy-variable-color` to keep the old
  look (`#eef2ff` and `#3730a3`).
- **Breaking:** these variables are removed. Set the Lexxy variable on the
  class instead.
  - `--lexxy-variable-radius`: `--lexxy-radius` on `.lexxy-variable`
  - `--lexxy-variables-menu-background`: `--lexxy-color-canvas` on
    `.lexxy-variables-menu`
  - `--lexxy-variables-menu-item-hover-background`:
    `--lexxy-color-ink-lightest` on `.lexxy-variables-menu__item`
  - `--lexxy-variables-option-code-color`: `--lexxy-color-ink-light` on
    `.lexxy-variables-option__code`
  - `--lexxy-variables-option-type-background` and
    `--lexxy-variables-option-type-color`: `--lexxy-color-ink-lightest` and
    `--lexxy-color-text-subtle` on `.lexxy-variables-option__type`
  - `--lexxy-variables-menu-min-width`: a `min-inline-size` rule on
    `.lexxy-variables-menu`
- Chip and option rules now have zero specificity, so a host rule for the
  class always wins, wherever it loads.
- Fix a selected chip hiding Lexxy's selection highlight. A selected chip now
  keeps its own shape and takes Lexxy's selection colors, which
  `--lexxy-variable-selected-background` and `--lexxy-variable-selected-color`
  override.
- Fix the toolbar dropdown opening past the editor's right edge.
- Fix the prompt width override widening every Lexxy prompt, mentions
  included. It now applies only to the variables prompt and stays inside the
  editor.
- Fix chips disappearing when saved content is edited. Chips with no record
  behind them, from a catalog of hashes or plain objects, showed as a missing
  attachment (☒) in the editor, and saving again deleted them. They now come
  back as chips, and read as their name in plain text. Content saved by
  earlier versions gets its chips back with no migration.
- Fix `LexxyVariables::Attachable`. Models that include it now save chips with
  the variable content type and render them as chips with no partial of their
  own. Before, Action Text's defaults won, so chips were saved as
  `application/octet-stream`, never resolved, and rendering them raised a
  missing partial error. Chips saved that way still carry the wrong type and
  aren't recognized.
- Fix a catalog of plain objects without `attachable_sgid` raising when the
  prompt renders. The README already listed it as optional.

## 0.0.5 (2026-07-19)

- Add a chainable `with_variables` API. `@record.body.with_variables(context:,
  **assigns)` returns a resolved `ActionText::Content`, so Action Text's own
  conversions chain from it: `.to_s` (sanitized HTML), `.to_plain_text`, and
  `.to_markdown` on Rails versions that ship it. Rendering in a view is now
  `<%= @record.body.with_variables %>`.
- **Breaking:** the `render_variable_content` helper is removed. Replace
  `render_variable_content(@record.body, ...)` with
  `@record.body.with_variables(...)`, which takes the same arguments.
- **Breaking:** the `content_layout` option is removed. Output renders under
  Action Text's standard layout. To change the wrapper, override
  `app/views/layouts/action_text/contents/_content.html.erb` like any other
  rich text.
- **Breaking:** values are now injected as DOM text nodes and escaped per
  output format, instead of being spliced into the rendered HTML string.
  In practice:
  - Liquid drops and values must no longer pre-escape. Delete the
    `ERB::Util.html_escape` calls from your drops, or values double-escape.
  - A Liquid value containing HTML now renders as literal text. Use a
    `renders_as: :html` attachment type for rich content.
  - Custom renderers implement `resolve_value(key, assigns)` instead of
    `render(html, nonce:, assigns:)`.
  - Author-typed `{{ }}` under the Liquid renderer now stays literal instead
    of rendering as `&#123;` entities. Only chip keys are parsed as Liquid.

## 0.0.4 (2026-07-14)

- Rename the view helper `render_lexxy_content` to `render_variable_content`.
- `render_variable_content` now accepts inline assigns. Pass a key's value
  straight to the call (`render_variable_content(@record.body, first_name:
  @user.first_name)` or an `assigns:` hash).
- Correct the importmap and npm install docs to use the `lexxy` import name.

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

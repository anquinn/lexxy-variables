# Changelog

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

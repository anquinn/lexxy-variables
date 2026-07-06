# lexxy-variables

Insert and safely resolve variables in [Lexxy](https://github.com/basecamp/lexxy)
rich text. The gem gives you an editor button (and a `{{` prompt) for inserting
variables into your text. Each variable is stored as an [Action Text
attachment](https://guides.rubyonrails.org/action_text_overview.html#rendering-attachments),
an `<action-text-attachment>` chip with its own content type, not as literal
`{{ var_name }}` markup. At render time the gem resolves each chip to its `value`.
You decide what variables exist and what they turn into.

Because variables are just Action Text attachments, you can register new
chip types with `register_attachment` (see [Full configuration](#full-configuration)):
a `:value` chip resolves to an escaped string, a `:fragment` chip splices rich
content in before sanitization.

Liquid is **optional**. The default renderer is plain, injection-safe string
substitution and pulls in no template engine.

<p align="center">
  <img src="docs/images/prompt-popup.png" alt="The {{ prompt listing variables inside the Lexxy editor" width="606">
</p>

## Requirements

Ruby 3.2+, Rails 8.0+, and a JavaScript bundler (esbuild, vite, or webpack).
See the note on importmap in [Install](#install).

## Install

Ruby:

```ruby
# Gemfile
gem "lexxy-variables"
```

JavaScript. The editor extension is distributed as an npm package, so you need a
bundler (esbuild, vite, webpack). Install it alongside Lexxy:

```sh
yarn add lexxy-variables @37signals/lexxy
```

Then register the extension in your JavaScript entrypoint:

```js
import VariableExtension from "lexxy-variables"
import * as Lexxy from "@37signals/lexxy"

Lexxy.configure({ global: { extensions: [ VariableExtension ] } })
```

The extension imports a few primitives from `lexical`, and Lexical is very
sensitive to running as a single instance. If your bundle ends up with two
copies of `lexical` (a common one: your app pulls a newer `lexical` than the
version Lexxy bundles), commands dispatched from one instance won't see nodes
from the other and inserts fail silently. If you hit that, pin `lexical` to the
version Lexxy bundles so everything dedupes to one copy:

```sh
# match the lexical Lexxy depends on (0.44.x for Lexxy 0.9.22)
yarn add lexical@0.44.0
```

> **importmap is not supported yet.** The extension needs `lexical` and
> `@37signals/lexxy` resolved to the same instance Lexxy runs, which importmap
> can't currently guarantee. The gem still ships the vendored JS and pins so it
> works the moment Lexxy exposes Lexical to extensions upstream
> ([basecamp/lexxy#1047](https://github.com/basecamp/lexxy/pull/1047)). Until
> then, use a bundler.

## Minimal configuration

`catalog` is the list users pick from in the editor. `assigns` is the lookup that
turns a key into a value at render time. `catalog` is required and `assigns` is
optional. Leave it out and the gem reads `value` straight off the catalog item.

Put the `configure` block in an initializer, e.g. `config/initializers/lexxy_variables.rb`:

```ruby
LexxyVariables.configure do |c|
  c.catalog = [ { key: "company", name: "Company", value: "Acme" } ]
end
```

The gem adds two view helpers, one for each side of the workflow: one to author
content and one to display it.

On the **editor page** (the form where content is composed), render the prompt
*inside* the Lexxy editor. The editor extension looks for the `<lexxy-prompt>`
within the `<lexxy-editor>` element, so it must be nested in the `rich_text_area`
block. That is what feeds the `{{` popup and the toolbar dropdown:

```erb
<%= form_with model: @record do |form| %>
  <%= form.rich_text_area :body do %>
    <%= lexxy_variables_prompt %>
  <% end %>
  <%= form.submit %>
<% end %>
```

Typing `{{` opens the prompt shown above, and there's also a toolbar dropdown
for picking from the same list. Inserted variables appear as chips in the editor:

<p align="center">
  <img src="docs/images/editor-chips.png" alt="Variable chips inline in the Lexxy editor" width="606">
</p>

On the **display page** (where the saved content is shown to readers), resolve
the stored rich text. This is what swaps each variable chip for its value:

```erb
<%= render_lexxy_content(@record.body) %>
```

Each chip resolves to its value, so the reader sees finished text:

<p align="center">
  <img src="docs/images/rendered-output.png" alt="The saved message with every variable chip resolved to its value" width="606">
</p>

`@record` and `:body` are placeholders. Use whatever model and Action Text
attribute hold your content.

## Full configuration

`context` is yours to define. The gem passes it untouched to your catalog,
assigns, and resolve callables, so put whatever they need in it. That might be a
tenant, `nil`, or any object.

```ruby
LexxyVariables.configure do |c|
  # The menu users pick from. A list, a zero-arg lambda, or a ->(context) lambda.
  c.catalog = ->(context) { context.variables + BuiltinVariable.all }

  # The lookup. Gets only the keys used in the content being rendered and returns
  # a { key => value } hash. ->(used_keys) also works if you don't need context.
  c.assigns = ->(context, used_keys) { MyResolver.assigns(context, used_keys) }

  # Opt into Liquid for dotted access / drops / filters.
  c.renderer = LexxyVariables::Renderers::Liquid.new

  # How the catalog is ordered in the prompt and dropdown. Defaults to :name
  # (case-insensitive alphabetical). Use :key to sort by key, false to keep the
  # catalog's given order, or a lambda: a ->(item) sort key or a ->(a, b) comparator.
  c.sort = :name

  # Register an extra attachment type. :fragment splices rich HTML pre-sanitize
  # (e.g. snippets) and its inner :value chips resolve in the same pass.
  c.register_attachment(
    content_type: "application/vnd.actiontext.snippet",
    phase: :fragment,
    label: "Snippet", # shown as a badge in the prompt when the list mixes types
    resolve: ->(node, context) { MySnippets.content_for(node, context) }
  )
end
```

## Multi-tenancy

Tenancy is optional. If your app is multi-tenant, pass the tenant through as
`context`. With [acts_as_tenant](https://github.com/ErwinM/acts_as_tenant) that
looks like:

```ruby
LexxyVariables.configure do |c|
  c.catalog = ->(tenant) { tenant.variables }
end
```

Both view helpers take the same `context:`. Pass the tenant on the editor page:

```erb
<%= form.rich_text_area :body do %>
  <%= lexxy_variables_prompt(context: ActsAsTenant.current_tenant) %>
<% end %>
```

and again on the display page:

```erb
<%= render_lexxy_content(@record.body, context: ActsAsTenant.current_tenant) %>
```

Or skip `context` entirely and rely on acts_as_tenant scoping queries to the
current tenant for you:

```ruby
LexxyVariables.configure do |c|
  c.catalog = -> { Variable.all }  # already scoped to ActsAsTenant.current_tenant
  c.assigns = ->(keys) { Variable.where(key: keys).pluck(:key, :value).to_h }
end
```

## Styling

The gem ships a default stylesheet so the editor UI works out of the box. Import
it and override the CSS custom properties (or the classes) to match your app.

```css
/* bundlers (esbuild, vite): */
@import "lexxy-variables/styles";
```

```ruby
# importmap / asset-pipeline hosts: the engine adds the vendored CSS to the asset
# paths. Link or @import "lexxy_variables.css".
```

Classes the gem emits: `.lexxy-variable` (token chip), `.lexxy-variable--block`
(chips that expand to a block, e.g. snippets), `.lexxy-variables-menu` /
`.lexxy-variables-menu__item` (the toolbar dropdown), and `.lexxy-variables-option`
/ `__header` / `__name` / `__type` / `__code` (option content, shared by the
`{{` prompt popup and the dropdown).

<p align="center">
  <img src="docs/images/toolbar-dropdown.png" alt="The toolbar dropdown listing the variable catalog" width="640">
</p>

Override without touching the classes:

```css
:root {
  --lexxy-variable-background: #fef3c7;
  --lexxy-variable-color: #92400e;
  --lexxy-variable-block-border: 1px dashed #f59e0b;
  --lexxy-variables-menu-item-hover-background: #f4f4f5;
  --lexxy-variables-option-code-color: #a1a1aa;
  --lexxy-variables-option-type-background: #f4f4f5;
  --lexxy-variables-option-type-color: #71717a;
  --lexxy-variables-prompt-max-width: 24rem; /* widen the {{ prompt popup (Lexxy caps at 20ch) */
}
```

Your prompt items should use the option classes so they appear the same in the
popup and the dropdown:

```erb
<template type="menu">
  <span class="lexxy-variables-option">
    <span class="lexxy-variables-option__name"><%= variable.name %></span>
    <code class="lexxy-variables-option__code">{{ <%= variable.key %> }}</code>
  </span>
</template>
```

## Security model

- Every render gets a fresh random nonce that guards the placeholder tokens, so an
  author can't fake a substitution by typing the token pattern into the body.
- Chips are swapped for those nonce tokens before the HTML is sanitized, and the
  real values go in afterward. A `:value` resolves to HTML-escaped text that can't
  do anything, while a `:fragment` is spliced in before sanitizing so the sanitizer
  still scrubs it.
- Only the Liquid renderer deals with template-engine braces (`{{ }}` and `{% %}`).
  The default renderer runs no engine at all, so there's nothing there to inject into.

## Contributing

Bug reports and pull requests are welcome. To get set up:

```sh
bundle install
bundle exec rake test     # run the test suite
bundle exec rubocop       # lint
```

The editor extension in `src/` is compiled into `vendor/` (the copy importmap
apps load). If you change anything under `src/`, rebuild before committing or CI
will fail:

```sh
npm install
npm run build
```

CI runs the tests across Ruby 3.2–4.0, rubocop, and a check that `vendor/`
matches `src/`.


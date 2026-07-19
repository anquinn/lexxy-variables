require "test_helper"
require "active_support/all"
require "action_view"
require "action_text"
require "liquid"

# ActionText::Content includes helpers that live in the engine's app/ directory,
# which is only on the load path inside a full Rails app. Load them by hand.
actiontext_root = Gem.loaded_specs["actiontext"].full_gem_path
require File.join(actiontext_root, "app/helpers/action_text/content_helper")
require File.join(actiontext_root, "app/helpers/action_text/tag_helper")

# Exercises the resolver against real ActionText fragments. The attachment
# types are registered here with resolvers that read node attributes, so no
# sgid machinery is needed. Assertions read the returned Content through
# ActionText's own conversions (#to_html, #to_plain_text).
class ResolverTest < ActiveSupport::TestCase
  VARIABLE_TYPE = "test/variable"
  SNIPPET_TYPE = "test/snippet"

  setup do
    @config = LexxyVariables::Configuration.new
    @config.register_attachment(
      content_type: VARIABLE_TYPE,
      resolve: ->(node, _context) { node["data-key"] }
    )
    @resolver = LexxyVariables::Resolver.new(@config)
  end

  def resolve(html, context: nil, locale: nil, assigns: {})
    content = ActionText::Content.new(html, canonicalize: false)
    @resolver.call(content, context: context, locale: locale, assigns: assigns)
  end

  def render(...)
    resolve(...).to_html
  end

  def variable_chip(key)
    %(<action-text-attachment content-type="#{VARIABLE_TYPE}" data-key="#{key}"></action-text-attachment>)
  end

  # A chip carrying the gem's real variable content-type, with the key embedded in
  # the content the way lexxy_variable_chip / the editor extension store it.
  def default_variable_chip(key)
    inner = %(<span class="lexxy-variable" data-lexxy-key="#{key}">#{key}</span>).gsub('"', "&quot;")
    %(<action-text-attachment content-type="#{LexxyVariables::VARIABLE_CONTENT_TYPE}" content="#{inner}"></action-text-attachment>)
  end

  def snippet_chip
    %(<action-text-attachment content-type="#{SNIPPET_TYPE}"></action-text-attachment>)
  end

  def register_snippet(&resolve)
    @config.register_attachment(content_type: SNIPPET_TYPE, renders_as: :html, resolve: resolve)
  end

  test "returns an ActionText::Content" do
    assert_instance_of ActionText::Content, resolve("<p>plain</p>")
  end

  test "resolves a value chip end to end" do
    @config.assigns = ->(_context, _keys) { { "company" => "Acme" } }

    assert_equal "<p>Hello Acme!</p>", render("<p>Hello #{variable_chip('company')}!</p>")
  end

  test "resolved values are escaped in html output" do
    @config.assigns = ->(_context, _keys) { { "company" => "<script>x</script>" } }

    out = render("<p>#{variable_chip('company')}</p>")

    refute_includes out, "<script>"
    assert_includes out, "&lt;script&gt;"
  end

  test "resolved values are raw in plain text output" do
    @config.assigns = ->(_context, _keys) { { "company" => "Tom & Jerry <3" } }

    out = resolve("<p>Hello #{variable_chip('company')}!</p>").to_plain_text

    assert_equal "Hello Tom & Jerry <3!", out
  end

  test "author-typed token pattern is not substituted" do
    @config.assigns = ->(_context, _keys) { { "company" => "Acme" } }
    forged = LexxyVariables::Placeholder.token("0000000000000000", "company")

    out = render("<p>#{forged} #{variable_chip('company')}</p>")

    assert_includes out, forged
    assert_includes out, "Acme"
  end

  test "unregistered attachments pass through untouched" do
    out = render(%(<p><action-text-attachment content-type="image/png"></action-text-attachment></p>))

    assert_includes out, %(content-type="image/png")
  end

  test "resolver returning nil drops the chip" do
    out = render("<p>a#{variable_chip('company').sub('data-key', 'data-other')}b</p>")

    assert_equal "<p>ab</p>", out
  end

  # The README's minimal configuration: a plain-hash catalog with a value and no
  # custom assigns or resolver. This exercises the default variable type, which
  # must recover the key from the chip's data-lexxy-key so default_assigns can
  # read the value off the catalog.
  test "default variable type resolves hash catalog end to end" do
    config = LexxyVariables::Configuration.new
    config.catalog = [ { key: "company", name: "Company", value: "Acme" } ]
    resolver = LexxyVariables::Resolver.new(config)

    content = ActionText::Content.new("<p>Hello #{default_variable_chip('company')}!</p>", canonicalize: false)
    out = resolver.call(content).to_html

    assert_includes out, "Hello Acme!"
  end

  test "used keys are passed to assigns deduplicated" do
    captured = nil
    @config.assigns = ->(_context, keys) { captured = keys and {} }

    render("<p>#{variable_chip('company')}#{variable_chip('company')}#{variable_chip('other')}</p>")

    assert_equal [ "company", "other" ], captured
  end

  # Inline assigns: per-render values passed to #call, merged on top of the
  # configured assigns. The catalog still governs what is insertable; these only
  # supply values at render time.

  test "inline assigns supply a value with no configured assigns" do
    out = render("<p>Hi #{variable_chip('first_name')}!</p>", assigns: { first_name: "Ada" })

    assert_equal "<p>Hi Ada!</p>", out
  end

  test "inline assigns override the configured assigns" do
    @config.assigns = ->(_context, _keys) { { "first_name" => "Config" } }

    out = render("<p>#{variable_chip('first_name')}</p>", assigns: { first_name: "Inline" })

    assert_equal "<p>Inline</p>", out
  end

  test "inline assigns are escaped in html output" do
    out = render("<p>#{variable_chip('first_name')}</p>", assigns: { first_name: "<script>x</script>" })

    refute_includes out, "<script>"
    assert_includes out, "&lt;script&gt;"
  end

  test "inline assigns with no matching chip are a no-op" do
    out = render("<p>plain</p>", assigns: { plan: "pro" })

    assert_equal "<p>plain</p>", out
  end

  test "inline assigns with no matching chip are a no-op under liquid" do
    @config.renderer = LexxyVariables::Renderers::Liquid.new

    out = render("<p>plain</p>", assigns: { plan: Object.new })

    assert_equal "<p>plain</p>", out
  end

  test "inline assigns pass drops through to liquid with string keys" do
    @config.renderer = LexxyVariables::Renderers::Liquid.new

    out = render("<p>#{variable_chip('company.name')}</p>", assigns: { company: CompanyDrop.new })

    assert_equal "<p>Acme</p>", out
  end

  test "context reaches resolvers and assigns" do
    seen = []
    @config.register_attachment(
      content_type: VARIABLE_TYPE,
      resolve: ->(node, context) { seen << context and node["data-key"] }
    )
    @config.assigns = ->(context, _keys) { seen << context and {} }

    render("<p>#{variable_chip('company')}</p>", context: :tenant)

    assert_equal [ :tenant, :tenant ], seen
  end

  test "fragment chip splices html and inner variables resolve in the same pass" do
    register_snippet { |_node, _context| "<p>Hi #{variable_chip('company')}</p>" }
    @config.assigns = ->(_context, _keys) { { "company" => "Acme" } }

    assert_equal "<p>Hi Acme</p>", render(snippet_chip)
  end

  test "nested fragments beyond max depth are dropped" do
    register_snippet { |_node, _context| "x#{snippet_chip}" }

    # The default depth of 1 expands the outer snippet and drops the nested one.
    assert_equal "x", render(snippet_chip)
  end

  test "deeper nesting is allowed when configured" do
    @config.max_fragment_depth = 2
    register_snippet { |_node, _context| "x#{snippet_chip}" }

    # Depth 2 expands twice, then the third level is dropped.
    assert_equal "xx", render(snippet_chip)
  end

  test "fragment resolver returning nil drops the chip" do
    register_snippet { |_node, _context| nil }

    assert_equal "<p>ab</p>", render("<p>a#{snippet_chip}b</p>")
  end

  # The tests above run the default no-Liquid substitution renderer. These run
  # the same resolver with the Liquid renderer switched on.

  class CompanyDrop < Liquid::Drop
    def name = "Acme"
  end

  class UnescapedDrop < Liquid::Drop
    def name = "Tom & Jerry"
  end

  test "liquid renderer replaces variables" do
    @config.renderer = LexxyVariables::Renderers::Liquid.new
    @config.assigns = ->(_context, _keys) { { "company" => "Acme" } }

    assert_equal "<p>Hello Acme!</p>", render("<p>Hello #{variable_chip('company')}!</p>")
  end

  test "liquid renderer replaces variables inside snippets" do
    @config.renderer = LexxyVariables::Renderers::Liquid.new
    @config.assigns = ->(_context, _keys) { { "company" => "Acme" } }
    register_snippet { |_node, _context| "<p>Hi #{variable_chip('company')}</p>" }

    assert_equal "<p>Hi Acme</p>", render(snippet_chip)
  end

  test "liquid renderer resolves dotted keys through drops" do
    @config.renderer = LexxyVariables::Renderers::Liquid.new
    @config.assigns = ->(_context, _keys) { { "company" => CompanyDrop.new } }

    assert_equal "<p>Acme</p>", render("<p>#{variable_chip('company.name')}</p>")
  end

  # Drops return raw values. The resolver escapes them for HTML output and
  # leaves them raw in plain text, so drops must not pre-escape.
  test "liquid values are escaped per format" do
    @config.renderer = LexxyVariables::Renderers::Liquid.new
    @config.assigns = ->(_context, _keys) { { "company" => UnescapedDrop.new } }

    content = resolve("<p>#{variable_chip('company.name')}</p>")

    assert_equal "<p>Tom &amp; Jerry</p>", content.to_html
    assert_equal "Tom & Jerry", content.to_plain_text
  end

  test "liquid renderer does not execute author-typed liquid" do
    @config.renderer = LexxyVariables::Renderers::Liquid.new

    out = render("<p>{{ 7 | plus: 1 }}</p>")

    refute_includes out, "8"
    assert_includes out, "{{ 7 | plus: 1 }}"
  end

  test "resolves under the requested locale" do
    locales_seen = []
    @config.register_attachment(
      content_type: VARIABLE_TYPE,
      resolve: ->(node, _context) { locales_seen << I18n.locale and node["data-key"] }
    )
    I18n.available_locales = [ :en, :fr ]

    render("<p>#{variable_chip('company')}</p>", locale: :fr)

    assert_equal [ :fr ], locales_seen
  end
end

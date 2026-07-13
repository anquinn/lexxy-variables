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

# Exercises the full render pipeline against real ActionText fragments. The
# view is faked with the two methods the pipeline calls, and the attachment
# types are registered here with resolvers that read node attributes, so no
# sgid machinery is needed.
class PipelineTest < Minitest::Test
  VARIABLE_TYPE = "test/variable"
  SNIPPET_TYPE = "test/snippet"

  FakeRichText = Struct.new(:body)

  class FakeView
    def render_action_text_content(content)
      content.fragment.source.to_html
    end

    def render(layout:, &block)
      block.call
    end
  end

  def setup
    @config = LexxyVariables::Configuration.new
    @config.register_attachment(
      content_type: VARIABLE_TYPE,
      resolve: ->(node, _context) { node["data-key"] }
    )
    @pipeline = LexxyVariables::Pipeline.new(FakeView.new, @config)
  end

  def render(html, context: nil, locale: nil, assigns: {})
    content = ActionText::Content.new(html, canonicalize: false)
    if locale
      @pipeline.call(FakeRichText.new(content), context: context, locale: locale, assigns: assigns)
    else
      @pipeline.call(FakeRichText.new(content), context: context, assigns: assigns)
    end
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

  def test_blank_body_renders_to_an_empty_html_safe_string
    assert_equal "", @pipeline.call(nil)
    assert_predicate @pipeline.call(nil), :html_safe?
  end

  def test_resolves_a_value_chip_end_to_end
    @config.assigns = ->(_context, _keys) { { "company" => "Acme" } }

    assert_equal "<p>Hello Acme!</p>", render("<p>Hello #{variable_chip('company')}!</p>")
  end

  def test_resolved_values_are_html_escaped
    @config.assigns = ->(_context, _keys) { { "company" => "<script>x</script>" } }

    out = render("<p>#{variable_chip('company')}</p>")

    refute_includes out, "<script>"
    assert_includes out, "&lt;script&gt;"
  end

  def test_author_typed_token_pattern_is_not_substituted
    @config.assigns = ->(_context, _keys) { { "company" => "Acme" } }
    forged = LexxyVariables::Placeholder.token("0000000000000000", "company")

    out = render("<p>#{forged} #{variable_chip('company')}</p>")

    assert_includes out, forged
    assert_includes out, "Acme"
  end

  def test_unregistered_attachments_pass_through_untouched
    out = render(%(<p><action-text-attachment content-type="image/png"></action-text-attachment></p>))

    assert_includes out, %(content-type="image/png")
  end

  def test_resolver_returning_nil_drops_the_chip
    out = render("<p>a#{variable_chip('company').sub('data-key', 'data-other')}b</p>")

    assert_equal "<p>ab</p>", out
  end

  # The README's minimal configuration: a plain-hash catalog with a value and no
  # custom assigns or resolver. This exercises the default variable type, which
  # must recover the key from the chip's data-lexxy-key so default_assigns can
  # read the value off the catalog. Previously every chip resolved to empty here.
  def test_default_variable_type_resolves_hash_catalog_end_to_end
    config = LexxyVariables::Configuration.new
    config.catalog = [ { key: "company", name: "Company", value: "Acme" } ]
    pipeline = LexxyVariables::Pipeline.new(FakeView.new, config)

    content = ActionText::Content.new("<p>Hello #{default_variable_chip('company')}!</p>", canonicalize: false)
    out = pipeline.call(FakeRichText.new(content))

    assert_includes out, "Hello Acme!"
  end

  def test_used_keys_are_passed_to_assigns_deduplicated
    captured = nil
    @config.assigns = ->(_context, keys) { captured = keys and {} }

    render("<p>#{variable_chip('company')}#{variable_chip('company')}#{variable_chip('other')}</p>")

    assert_equal [ "company", "other" ], captured
  end

  # Inline assigns: per-render values passed to #call, merged on top of the
  # configured assigns. The catalog still governs what is insertable; these only
  # supply values at render time.

  def test_inline_assigns_supply_a_value_with_no_configured_assigns
    out = render("<p>Hi #{variable_chip('first_name')}!</p>", assigns: { first_name: "Ada" })

    assert_equal "<p>Hi Ada!</p>", out
  end

  def test_inline_assigns_override_the_configured_assigns
    @config.assigns = ->(_context, _keys) { { "first_name" => "Config" } }

    out = render("<p>#{variable_chip('first_name')}</p>", assigns: { first_name: "Inline" })

    assert_equal "<p>Inline</p>", out
  end

  def test_inline_assigns_are_html_escaped_under_the_default_renderer
    out = render("<p>#{variable_chip('first_name')}</p>", assigns: { first_name: "<script>x</script>" })

    refute_includes out, "<script>"
    assert_includes out, "&lt;script&gt;"
  end

  def test_inline_assigns_with_no_matching_chip_are_a_no_op
    out = render("<p>plain</p>", assigns: { plan: "pro" })

    assert_equal "<p>plain</p>", out
  end

  def test_inline_assigns_with_no_matching_chip_are_a_no_op_under_liquid
    @config.renderer = LexxyVariables::Renderers::Liquid.new

    out = render("<p>plain</p>", assigns: { plan: Object.new })

    assert_equal "<p>plain</p>", out
  end

  def test_inline_assigns_pass_drops_through_to_liquid_with_string_keys
    @config.renderer = LexxyVariables::Renderers::Liquid.new

    out = render("<p>#{variable_chip('company.name')}</p>", assigns: { company: CompanyDrop.new })

    assert_equal "<p>Acme</p>", out
  end

  def test_context_reaches_resolvers_and_assigns
    seen = []
    @config.register_attachment(
      content_type: VARIABLE_TYPE,
      resolve: ->(node, context) { seen << context and node["data-key"] }
    )
    @config.assigns = ->(context, _keys) { seen << context and {} }

    render("<p>#{variable_chip('company')}</p>", context: :tenant)

    assert_equal [ :tenant, :tenant ], seen
  end

  def test_fragment_chip_splices_html_and_inner_variables_resolve_in_the_same_pass
    register_snippet { |_node, _context| "<p>Hi #{variable_chip('company')}</p>" }
    @config.assigns = ->(_context, _keys) { { "company" => "Acme" } }

    assert_equal "<p>Hi Acme</p>", render(snippet_chip)
  end

  def test_nested_fragments_beyond_max_depth_are_dropped
    register_snippet { |_node, _context| "x#{snippet_chip}" }

    # The default depth of 1 expands the outer snippet and drops the nested one.
    assert_equal "x", render(snippet_chip)
  end

  def test_deeper_nesting_is_allowed_when_configured
    @config.max_fragment_depth = 2
    register_snippet { |_node, _context| "x#{snippet_chip}" }

    # Depth 2 expands twice, then the third level is dropped.
    assert_equal "xx", render(snippet_chip)
  end

  def test_fragment_resolver_returning_nil_drops_the_chip
    register_snippet { |_node, _context| nil }

    assert_equal "<p>ab</p>", render("<p>a#{snippet_chip}b</p>")
  end

  # The tests above run the default no-Liquid substitution renderer. These run
  # the same pipeline with the Liquid renderer switched on.

  class CompanyDrop < Liquid::Drop
    def name = "Acme"
  end

  def test_liquid_renderer_replaces_variables
    @config.renderer = LexxyVariables::Renderers::Liquid.new
    @config.assigns = ->(_context, _keys) { { "company" => "Acme" } }

    assert_equal "<p>Hello Acme!</p>", render("<p>Hello #{variable_chip('company')}!</p>")
  end

  def test_liquid_renderer_replaces_variables_inside_snippets
    @config.renderer = LexxyVariables::Renderers::Liquid.new
    @config.assigns = ->(_context, _keys) { { "company" => "Acme" } }
    register_snippet { |_node, _context| "<p>Hi #{variable_chip('company')}</p>" }

    assert_equal "<p>Hi Acme</p>", render(snippet_chip)
  end

  def test_liquid_renderer_resolves_dotted_keys_through_drops
    @config.renderer = LexxyVariables::Renderers::Liquid.new
    @config.assigns = ->(_context, _keys) { { "company" => CompanyDrop.new } }

    assert_equal "<p>Acme</p>", render("<p>#{variable_chip('company.name')}</p>")
  end

  def test_liquid_renderer_does_not_execute_author_typed_liquid
    @config.renderer = LexxyVariables::Renderers::Liquid.new

    out = render("<p>{{ 7 | plus: 1 }}</p>")

    refute_includes out, "8"
    assert_includes out, "&#123;&#123;"
  end

  def test_renders_under_the_requested_locale
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

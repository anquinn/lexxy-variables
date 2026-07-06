require "test_helper"

class ConfigurationTest < Minitest::Test
  def setup
    @config = LexxyVariables::Configuration.new
  end

  Item = Struct.new(:key, :name, :value)

  def test_variable_type_is_pre_registered
    match = @config.registry.match("content-type" => LexxyVariables::VARIABLE_CONTENT_TYPE)

    refute_nil match
    assert_equal :value, match.phase
  end

  def test_catalog_accepts_a_plain_list
    @config.catalog = [ { key: "a", name: "A" } ]

    assert_equal [ { key: "a", name: "A" } ], @config.resolve_catalog(:ignored)
  end

  def test_catalog_accepts_a_zero_arg_callable
    @config.catalog = -> { [ :computed ] }

    assert_equal [ :computed ], @config.resolve_catalog(:ignored)
  end

  def test_catalog_accepts_a_context_callable
    @config.catalog = ->(context) { [ context ] }

    assert_equal [ :the_context ], @config.resolve_catalog(:the_context)
  end

  def test_default_assigns_reads_value_from_hash_items
    @config.catalog = [ { key: "company", name: "Company", value: "Acme" } ]

    assert_equal({ "company" => "Acme" }, @config.resolve_assigns(nil, [ "company" ]))
  end

  def test_default_assigns_reads_value_from_object_items
    @config.catalog = [ Item.new("company", "Company", "Acme") ]

    assert_equal({ "company" => "Acme" }, @config.resolve_assigns(nil, [ "company" ]))
  end

  def test_default_assigns_skips_unknown_keys
    @config.catalog = [ { key: "company", name: "Company", value: "Acme" } ]

    assert_equal({}, @config.resolve_assigns(nil, [ "missing" ]))
  end

  def test_assigns_override_with_two_args
    @config.assigns = ->(context, keys) { { context: context, keys: keys } }

    assert_equal({ context: :the_context, keys: [ "a" ] }, @config.resolve_assigns(:the_context, [ "a" ]))
  end

  def test_assigns_override_with_one_arg
    @config.assigns = ->(keys) { { keys: keys } }

    assert_equal({ keys: [ "a" ] }, @config.resolve_assigns(:the_context, [ "a" ]))
  end

  def test_catalog_sorts_by_name_alphabetically_by_default
    @config.catalog = [
      { key: "c", name: "Charlie" },
      { key: "a", name: "alpha" },
      { key: "b", name: "Bravo" }
    ]

    assert_equal %w[a b c], @config.resolve_catalog(nil).map { |i| i[:key] }
  end

  def test_catalog_sort_by_key
    @config.sort = :key
    @config.catalog = [ { key: "z", name: "A" }, { key: "a", name: "Z" } ]

    assert_equal %w[a z], @config.resolve_catalog(nil).map { |i| i[:key] }
  end

  def test_catalog_sort_false_preserves_given_order
    @config.sort = false
    @config.catalog = [ { key: "c", name: "C" }, { key: "a", name: "A" } ]

    assert_equal %w[c a], @config.resolve_catalog(nil).map { |i| i[:key] }
  end

  def test_catalog_sort_with_key_callable
    @config.sort = ->(item) { item[:name] }
    @config.catalog = [ { key: "b", name: "B" }, { key: "a", name: "A" } ]

    assert_equal %w[a b], @config.resolve_catalog(nil).map { |i| i[:key] }
  end

  def test_catalog_sort_with_comparator_callable
    @config.sort = ->(a, b) { b[:name] <=> a[:name] }
    @config.catalog = [ { key: "a", name: "A" }, { key: "b", name: "B" } ]

    assert_equal %w[b a], @config.resolve_catalog(nil).map { |i| i[:key] }
  end

  def test_register_attachment_adds_a_type
    @config.register_attachment(
      content_type: "application/vnd.actiontext.snippet",
      phase: :fragment,
      resolve: ->(node, context) { "html" }
    )

    match = @config.registry.match("content-type" => "application/vnd.actiontext.snippet")
    assert_equal :fragment, match.phase
  end

  # The default variable resolver is what a plain-hash catalog (the README's
  # minimal config) relies on: with no sgid-backed attachable it must recover the
  # key from the data-lexxy-key that lexxy_variable_chip embeds in the chip
  # content. Without this the resolver returns nil and every chip renders empty.
  def test_default_variable_type_resolves_key_from_chip_content
    type = @config.registry.match("content-type" => LexxyVariables::VARIABLE_CONTENT_TYPE)
    node = chip_node(key: "company")

    assert_equal "company", type.resolve.call(node, nil)
  end

  def test_default_variable_type_resolves_to_nil_when_no_key_present
    type = @config.registry.match("content-type" => LexxyVariables::VARIABLE_CONTENT_TYPE)
    node = chip_node(content: "<span>no key here</span>")

    assert_nil type.resolve.call(node, nil)
  end

  def test_chip_key_reads_data_lexxy_key
    assert_equal "renewal_date", LexxyVariables.chip_key(chip_node(key: "renewal_date"))
  end

  def test_chip_key_is_nil_without_content
    assert_nil LexxyVariables.chip_key(chip_node(content: nil))
    assert_nil LexxyVariables.chip_key(chip_node(content: ""))
  end

  def test_chip_key_is_nil_when_key_is_blank
    assert_nil LexxyVariables.chip_key(chip_node(content: %(<span data-lexxy-key="">X</span>)))
  end

  private

  # Builds the <action-text-attachment> node the pipeline hands a resolver. The
  # key lives inside the (HTML-escaped) content attribute, exactly as the editor
  # extension stores it. Pass :content to override the whole content string.
  def chip_node(key: nil, content: :default)
    inner = content == :default ? %(<span class="lexxy-variable" data-lexxy-key="#{key}">#{key}</span>) : content
    attrs = %(content-type="#{LexxyVariables::VARIABLE_CONTENT_TYPE}")
    attrs += %( content="#{inner.gsub('"', "&quot;")}") unless inner.nil?

    Nokogiri::HTML5.fragment("<action-text-attachment #{attrs}></action-text-attachment>")
      .at_css("action-text-attachment")
  end
end

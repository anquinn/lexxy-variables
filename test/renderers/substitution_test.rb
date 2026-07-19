require "test_helper"

class SubstitutionRendererTest < ActiveSupport::TestCase
  setup do
    @renderer = LexxyVariables::Renderers::Substitution.new
  end

  test "resolves a key from assigns" do
    assert_equal "Acme", @renderer.resolve_value("company", { "company" => "Acme" })
  end

  test "missing key becomes empty" do
    assert_equal "", @renderer.resolve_value("company", {})
  end

  test "returns the value raw" do
    # Escaping happens per output format at serialization, not here.
    value = "<b>Tom & Jerry</b>"

    assert_equal value, @renderer.resolve_value("company", { "company" => value })
  end

  test "no template engine means the key is a plain lookup" do
    assert_equal "", @renderer.resolve_value("7 | plus: 1", { "company" => "Acme" })
  end
end

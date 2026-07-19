require "test_helper"
require "liquid"

class LiquidRendererTest < ActiveSupport::TestCase
  class CompanyDrop < Liquid::Drop
    def name = "Tom & Jerry"
  end

  setup do
    @renderer = LexxyVariables::Renderers::Liquid.new
  end

  test "resolves a key from assigns" do
    assert_equal "Acme", @renderer.resolve_value("company", { "company" => "Acme" })
  end

  test "resolves dotted keys through drops" do
    assert_equal "Tom & Jerry", @renderer.resolve_value("company.name", { "company" => CompanyDrop.new })
  end

  test "missing key becomes empty" do
    assert_equal "", @renderer.resolve_value("company", {})
  end

  test "values are returned raw" do
    # Drops must not pre-escape: escaping happens per output format at
    # serialization after the resolver injects the value as text
    assert_equal "a < b", @renderer.resolve_value("x", { "x" => "a < b" })
  end
end

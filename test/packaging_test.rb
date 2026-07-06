require "test_helper"

# Bundler auto-requires a gem by its dashed name. The implementation lives in
# lexxy_variables.rb (underscore), so a lib/lexxy-variables.rb shim bridges the
# two. Without it, `gem "lexxy-variables"` loads nothing (no engine, helper, or
# assets) and the failure is silent. Guard the shim so it can't be dropped.
class PackagingTest < Minitest::Test
  def test_dashed_name_is_requirable
    require "lexxy-variables"
    assert defined?(LexxyVariables), "requiring the dashed name must define LexxyVariables"
  rescue LoadError => e
    flunk "gem \"lexxy-variables\" is not loadable by its dashed name: #{e.message}"
  end

  def test_shim_file_ships_with_the_gem
    shim = File.expand_path("../lib/lexxy-variables.rb", __dir__)

    assert File.exist?(shim), "lib/lexxy-variables.rb shim is missing"
  end
end

require_relative "lib/lexxy_variables/version"

Gem::Specification.new do |spec|
  spec.name        = "lexxy-variables"
  spec.version     = LexxyVariables::VERSION
  spec.authors     = [ "Andrew Quinn" ]
  spec.summary     = "Insert and safely resolve variables in Lexxy rich text, stored as Action Text attachment chips."
  spec.description = <<~DESC
    Insert and safely resolve variables in Lexxy rich text. The gem gives you an
    editor button (and a `{{` prompt) for inserting variables, each stored as an
    Action Text attachment chip rather than literal markup. `with_variables`
    resolves the chips and returns plain Action Text content. Register new chip types
    with `register_attachment`. A :text chip resolves to an escaped string, an
    :html chip splices rich content in before sanitization. Liquid is optional.
    The default renderer is plain, injection-safe string substitution and pulls
    in no template engine.
  DESC
  spec.homepage = "https://github.com/anquinn/lexxy-variables"
  spec.license  = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata = {
    "source_code_uri" => spec.homepage,
    "changelog_uri"   => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "#{spec.homepage}/issues"
  }

  spec.files = Dir[
    "lib/**/*", "app/**/*", "config/**/*", "vendor/**/*",
    "README.md", "LICENSE"
  ]
  spec.require_paths = [ "lib" ]

  # Rails plumbing the pipeline sits on top of. Liquid is deliberately absent.
  # It is opt-in and loaded by Renderers::Liquid only when a host wires it up.
  spec.add_dependency "railties", ">= 8.0"
  spec.add_dependency "actiontext", ">= 8.0"
  spec.add_dependency "actionview", ">= 8.0"
  spec.add_dependency "activesupport", ">= 8.0"
  spec.add_dependency "nokogiri", ">= 1.15"

  spec.add_development_dependency "liquid", ">= 5.0"
  spec.add_development_dependency "minitest", ">= 5.0"
end

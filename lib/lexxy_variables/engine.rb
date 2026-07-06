module LexxyVariables
  # Wires the gem into a host Rails app: mixes in the helper and exposes the
  # vendored JS so importmap apps can pin it with no JS tooling. Bundler apps
  # (esbuild, etc.) instead resolve the npm package from node_modules and ignore
  # the vendored copy.
  class Engine < ::Rails::Engine
    initializer "lexxy_variables.helper" do
      ActiveSupport.on_load(:action_view) do
        include LexxyVariables::Helper
      end
    end

    # Make the vendored JS + CSS resolvable by the asset pipeline (Propshaft/Sprockets).
    initializer "lexxy_variables.assets" do |app|
      if app.config.respond_to?(:assets)
        app.config.assets.paths << root.join("vendor/javascript").to_s
        app.config.assets.paths << root.join("vendor/stylesheets").to_s
      end
    end

    # Pin the vendored module for importmap-rails hosts. Without importmap-rails
    # the config key does not exist and this initializer does nothing.
    initializer "lexxy_variables.importmap", before: "importmap" do |app|
      if app.config.respond_to?(:importmap)
        app.config.importmap.paths << root.join("config/importmap.rb")
      end
    end
  end
end

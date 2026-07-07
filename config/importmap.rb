# Importmap pins for host apps using importmap-rails. Bundler-based hosts ignore
# these and resolve the npm packages from node_modules instead.
pin "lexxy-variables", to: "lexxy_variables.js", preload: true

# The extension imports "@37signals/lexxy"; lexxy's docs have hosts pin the same
# file as "lexxy". Both specifiers resolve to one URL, so the browser loads a
# single module instance (Lexical breaks silently if there are two).
pin "@37signals/lexxy", to: "lexxy.js"

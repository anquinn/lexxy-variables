# Bundler auto-requires a gem by its dashed name ("lexxy-variables"), but the
# implementation lives in lexxy_variables.rb (the LexxyVariables namespace). This
# shim bridges the two so `gem "lexxy-variables"` loads the gem with no `require:`.
require "lexxy_variables"

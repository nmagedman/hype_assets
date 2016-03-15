require "hype_assets/version"
require "hype_assets/hype_template"
require "sprockets"

Sprockets::Engines #force autoloading.   Necessary?
Sprockets.register_engine '.hype', ::HypeAssets::HypeTemplate

require "hype_assets/version"
require "hype_assets/hype_template"
require "sprockets"
require "rails"


## Register *_hype_generated_script.js.hype files to be processed by us
Sprockets.register_engine '.hype', ::HypeAssets::HypeTemplate

## Add hype files (`*.hyperesources/*.js`) to assets precompile array
Rails::Application.initializer "hype_assets" do
	Rails.logger.info "HypeAssets: Adding hype files (`*.hyperesources/*.js`) to assets precompile array"
	Rails.application.config.assets.precompile += %w[ *.hyperesources/*.js ]
end

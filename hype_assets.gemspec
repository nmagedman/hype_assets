# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hype_assets/version'

Gem::Specification.new do |spec|
	spec.name          = "hype_assets"
	spec.version       = HypeAssets::VERSION
	spec.authors       = ["Noach Magedman"]
	spec.email         = ["nmagedman@gmail.com"]

	spec.summary       = %q{Integrate Tumult Hype 3 animation files into the Rails Asset Pipeline}
	spec.description   = %q{Append `.hype` to your hype_generated_script.js and we take care of the rest!}
	spec.homepage      = "https://github.com/nmagedman/hype_assets"
	spec.license       = "MIT"

	spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
	spec.bindir        = "exe"
	spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
	spec.require_paths = ["lib"]

	spec.add_development_dependency "bundler", ">= 1.11"
	spec.add_development_dependency "rake", ">= 10.0"
	spec.add_development_dependency "rspec", ">= 3.0"

	spec.add_runtime_dependency 'sprockets', '~> 3.0' # 2.x used the Tilt interface
	spec.add_runtime_dependency 'rails', '~> 4.0'
end

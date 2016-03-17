class HypeAssets::HypeTemplate

	def self.call (input)
	### Massage the raw foo.hyperesources/foo_hype_generated_script.js.hype file
	### to use digested filenames, stored potentially on a CDN.
	### @input [Hash] See http://www.rubydoc.info/gems/sprockets/3.5.2#Processor_Interface
	###   for a description of input's fields.
	### @returns [String or Hash] see sprockets README
puts "HypeAssets: Processing #{input[:name]} @ #{Time.now}"
		hype_script = input[:data]
		folder = nil

		## THE BASE URL:
		## Replace: var f="animation_name.hyperesources"
		## With:    var f="https://my.cdn.com/assets/animation_name.hyperesources"
		hype_script.sub!(/var f="([^"]+)"/) {
			folder = $1
			## TODO: Don't hardcode `assets`.  Get it dynamically from the config.
			path = asset_url "assets/#{folder}"
			%Q[var f="#{path}"]
		}


		## The HYPE Library:
		## Replace: "HYPE-466.full.min.js":"HYPE-466.thin.min.js"
		## With:    "HYPE-466.full.min-1234567890abcdef.js":"HYPE-466.thin.min-1234567890abcdef.js"
		hype_script.sub!(/"(HYPE-\d+.full.min.js)":"(HYPE-\d+.thin.min.js)"/) {
			full = digested_asset_filename "#{folder}/#{$1}"
			thin = digested_asset_filename "#{folder}/#{$2}"
			%Q["#{full}":"#{thin}"]
		}


		## INDIVIDUAL FILENAMES:
		## Replace: n:"my_image.png"
		## With:    n:"my_image-1234567890abcdef.png"
		## TODO: A big difficulty here is choosing which instances of `n:""` to modify:
		##   n is used both for filenames and for free-form, scene names.
		##   Currently, I assume the filenames have a dot (reasonable, because they have extensions)
		##   and that scene names do not (not so reasonable, since a human types them in).
		##   With tighter pattern matching, we may be able to support scene-names containing dots.
		##   For example, all the filenames are grouped together in a hash which is the third
		##   argument to `new HYPE_466()`.   Of course, that could change from version to version
		##   of Hype!
		hype_script.gsub!(/\bn:"([^"]+\.[^"]+)"/) {
			n = digested_asset_filename "#{folder}/#{$1}"
			%Q[n:"#{n}"]
		}

		"// Pre-Processed with HypeAssets v#{::HypeAssets::VERSION} @ #{Time.now}\n#{hype_script}"
	end


	def self.digested_asset_filename (resource)
	### @returns the digested version of an asset's filename.
	### It returns *just* the filename itself (i.e. the basename),
	### since Hype's script internally concatenates the filename
	### onto a base URL.
		### NOTE: The Hype *_hype_generated_script.js percent-encodes the filename.
		### Incidentally, it encodes `@`, even though this is a safe character, AFAICT.
		### URI.encode does *not* re-encode the `@`, but that doesn't seem to break things.

		decoded_resource = URI.decode    resource
		digested_path    = digest_path   decoded_resource
		basename         = File.basename digested_path
		re_encoded_name  = URI.encode    basename
	end


	def self.asset_url (resource)
	### Wrapper function around the Sprockets helper,
	### since it's not clear how best to invoke it.
		ApplicationController.helpers.asset_url resource
	end


	def self.digest_path (resource)
	### Wrapper function around the Sprockets helper,
	### since it's not clear how best to invoke it.
		## To ensure we have the digested version of the filename,
		## we have to load the Sprockets::Asset into memory.
		Rails.application.assets.find_asset(resource).digest_path
	end
end

class HypeAssets::HypeTemplate


	def self.cache_key
	### Sprockets stores our processor's cache key along with the compiled asset.
	### If we change the key, the compiled asset is invalidated and recompiled.
	### Grep for @cache_key within the sprockets gem for examples of its definition.
	### Things we might include here:
	###   * gem or class name
	###   * gem version
	###   * version of any external libraries used
	###   * configuration options, as `DigestUtils.digest(options)`
		@cache_key ||= "#{name}:#{::HypeAssets::VERSION}"
	end


	def self.call (input)
	### Massage the raw foo.hyperesources/foo_hype_generated_script.js.hype file
	###   to use digested filenames, stored potentially on a CDN.
	### @param input [Hash] See http://www.rubydoc.info/gems/sprockets/3.5.2#Processor_Interface
	###   for a description of input's fields.
	### @return [Hash] :data is the post-processed content.   All other fields are merged into the :metadata hash.  See lib/sprockets/processor_utils.rb#call_processors()

		hype_script  = input[:data]
		sprockets    = input[:environment]
		dependencies = Set.new(input[:metadata][:dependencies])  # may be nil
		folder       = nil

		sprockets.logger.info "HypeAssets: Processing #{input[:name]} @ #{Time.now}"


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
			full = digested_asset_filename "#{folder}/#{$1}", dependencies, sprockets
			thin = digested_asset_filename "#{folder}/#{$2}", dependencies, sprockets
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
			n = digested_asset_filename "#{folder}/#{$1}", dependencies, sprockets
			%Q[n:"#{n}"]
		}

		hype_script = "// Pre-Processed with HypeAssets v#{::HypeAssets::VERSION} @ #{Time.now}\n #{hype_script}"


		{
			data:  hype_script,
			dependencies: dependencies,
		}
	end


	def self.digested_asset_filename (resource, dependencies, sprockets)
	### @param resource [String] uri-encoded asset, e.g. "folder/file%402x.jpg"
	### @param dependencies [Set] (mutated) resource is added to the set
	### @param sprockets [Sprockets::Environment] needed for its helper functions
	### @return digested version of the asset's filename.
	###         Returns *just* the filename itself (i.e. the basename),
	###         since Hype's script internally concatenates the filename
	###         onto a base URL.
		### NOTE: The Hype *_hype_generated_script.js percent-encodes the filename.
		### Incidentally, it encodes `@`, even though this is a safe character, AFAICT.
		### URI.encode does *not* re-encode the `@`, but that doesn't seem to break things.

		decoded_resource = URI.decode    resource
		digested_path    = digest_path   decoded_resource
		basename         = File.basename digested_path
		re_encoded_name  = URI.encode    basename


		## Ensure our .hype file will be recompiled if any of our images change.
		## The Sprockets documentation is sorely lacking in explaining how to do this.
		## From experimentation, we need an absolute file-digest:// URI:
		##    "file-digest:///absolute/path/to/foo.hyperesources/file"
		## Anything less will be silently ignored, including:
		##    "foo.hyperesources/file"
		##    "file-digest:///foo.hyperesources/file"
		##    "/absolute/path/to/foo.hyperesources/file"
		absolute_path = sprockets.resolve(decoded_resource)
		file_digest_uri = sprockets.build_file_digest_uri(absolute_path)
			## NOTE: build_file_digest_uri just tacks on a file-digest:// prefix.
			## It does //not// generate a digest hashcode.
		dependencies << file_digest_uri

		re_encoded_name
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

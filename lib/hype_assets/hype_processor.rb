class HypeAssets::HypeProcessor


	### Sprockets stores our processor’s cache key along with the compiled asset.
	### If we change the key, the compiled asset is invalidated and recompiled.
	### Grep for @cache_key within the sprockets gem for examples of its definition.
	### Things we might include here:
	###   * gem or class name
	###   * gem version
	###   * version of any external libraries used
	###   * configuration options, as `DigestUtils.digest(options)`
	def self.cache_key
		@cache_key ||= "#{name}:#{::HypeAssets::VERSION}"
	end


	### Massage the raw foo.hyperesources/foo_hype_generated_script.js.hype file
	###   to use digested filenames, stored potentially on a CDN.
	### @param input [Hash] See
	###   http://www.rubydoc.info/gems/sprockets/3.5.2#Processor_Interface
	###   for a description of input's fields.
	### @return [Hash]
	###   :data [String] is the post-processed content (i.e. the massaged hype script).
	###   All other fields are merged into the input[:metadata] hash.
	###   See lib/sprockets/processor_utils.rb#call_processors()
	def self.call (input)

		hype_script  = input[:data]          # [String] *.js.hype file contents
		sprockets    = input[:environment]   # [Sprockets::Environment]
		dependencies = Set.new(input[:metadata][:dependencies])  # may be nil
		folder       = nil  # => animation_name.hyperesources
		base_url     = nil  # => https://my.cdn.com/assets/animation_name.hyperesources

		sprockets.logger.info "HypeAssets: Processing #{input[:name]} @ #{Time.now}"


		## THE BASE URL:
		## Replace: var f="animation_name.hyperesources"
		## With:    var f="https://my.cdn.com/assets/animation_name.hyperesources"
		## NOTE: In HYPE-4xx this variable was called f.   In HYPE-5xx it's called h.
		## We should be varname agnostic.  In any case, it is the first (and only?)
		## instance of a string ending in `.hyperesources`.
		## We can assume that it will continue to be a variable assignment.
		hype_script.sub!(/="([^"]+\.hyperesources)"/) {
			folder     = $1

			asset_host = sprockets.context_class.config.asset_host  # shouldn't end in /
			prefix     = sprockets.context_class.assets_prefix      # begins with /
			base_url   = "#{asset_host}#{prefix}/#{folder}"
			%Q[="#{base_url}"]
		}


		## The HYPE Library:
		## Replace: ?"HYPE-466.full.min.js":"HYPE-466.thin.min.js"
		## With:    ?"HYPE-466.full.min-1234567890.js":"HYPE-466.thin.min-1234567890.js"
		hype_script.sub!(/\?"(HYPE-\d+.full.min.js)":"(HYPE-\d+.thin.min.js)"/) {
			full = digested_asset_filename $1, folder, dependencies, sprockets
			thin = digested_asset_filename $2, folder, dependencies, sprockets
			%Q[?"#{full}":"#{thin}"]
		}


		## INDIVIDUAL FILENAMES:
		## Replace: n:"my_image.png"
		## With:    n:"my_image-1234567890abcdef.png"
		##
		## We should be varname agnostic, as Tumult might rename the hash keys.
		## That means we will be checking every hash value string to see if it’s
		## a file.  Only consider strings that _look_ like filenames, and tolerate
		## failed lookups gracefully -- treat them as non-file strings.
		hype_script.gsub!(/(^|[,{])(\w+):"([\w\-%]++\.[\w\-%.]++)"/) {
			preamble = $1  # a hashkey will only follow a curly brace, comma, or newline
			hashkey  = $2
			filename = $3  # Must have 1+ dots.  Aggressively URL-encoded.

			daf = digested_asset_filename filename, folder, dependencies, sprockets
			if daf
				%Q[#{preamble}#{hashkey}:"#{daf}"]
			else
				$&  # if anything goes wrong, just leave everything untouched.
			end
		}

		## CSS FONT-FACE DATA:
		## Replace: url('animation_name.hyperesources/custom_font.svg#fontname')
		## With:    url('https://my.cdn.com/assets/animation_name.hyperesources/custom_font-12345.svg#fontname')
		##
		## The CSS `<style>` tag and its content are inserted into the page dynamically.
		## The CSS code is typed into the Hype editor **manually** in the
		## Inspector > Text > Add More Fonts > Custom CSS > Embedded Head HTML
		## textfield.
		## See http://tumult.com/hype/documentation/3.0/#declaring-an-font-face-style
		##
		## So realize that the syntax will be less consistent than the rest of the file.
		## e.g. url() strings may be single-quoted, double-quoted, or not quoted at all.
		## Nonetheless, the entire injected content is stored as a double-quoted string,
		## so "whitespace" (other than spaces) will appear as \t, \n, or \r.
		##
		## For now, the only URL path we will support is `foo.hyperesources/filename`
		##
		hype_script.gsub!(
			/(\b|\\[tnr])url\(('|\\")?#{Regexp.quote folder}\/([\w\-%.]++)([?#].*?)?\2\)/
		) {
			preamble   = $1  # leading whitespace
			quote      = $2  # single, double, or nothing
			filename   = $3  # URL-encoded?
			extra_junk = $4  # svg fonts need a #fontname fragment.
			                 # And IE needs a hack, of course.

			daf = digested_asset_filename filename, folder, dependencies, sprockets
			if daf
				%Q[#{preamble}url(#{quote}#{base_url}/#{daf}#{extra_junk}#{quote})]
			else
				$&  # if anything goes wrong, just leave everything untouched.
			end
		}


		hype_script = "// Pre-Processed with HypeAssets v#{::HypeAssets::VERSION} @ #{Time.now}\n#{hype_script}"

		{
			data:         hype_script,
			dependencies: dependencies,
		}
	end


	### @param filename [String] uri-encoded, e.g. "file%402x.jpg"
	### @param folder [String] "animation_name.hyperesources"
	### @param dependencies [Set] (mutated) asset is added to the set
	### @param sprockets [Sprockets::Environment] needed for its helper functions
	### @return digested version of the asset’s filename.
	###         Returns *just* the filename itself (i.e. the basename),
	###         since Hype’s script internally concatenates the filename
	###         onto a base URL.
	def self.digested_asset_filename (filename, folder, dependencies, sprockets)
		### NOTE: The Hype *_hype_generated_script.js percent-encodes the filename.
		### Incidentally, it encodes `@`, even though this is a safe character, AFAICT.
		### URI.encode does *not* re-encode the `@`, but that doesn't seem to break
		### things.


		decoded_filename = URI.decode    filename
		resource         = "#{folder}/#{decoded_filename}"
		digested_path    = digest_path   resource
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
		absolute_path   = sprockets.resolve(resource)
		file_digest_uri = sprockets.build_file_digest_uri(absolute_path)
			## NOTE: build_file_digest_uri just tacks on a `file-digest://` prefix.
			## It does //not// generate a digest hashcode.
		dependencies << file_digest_uri

		re_encoded_name
	rescue NoMethodError => e
		puts "HypeAssets: Unable to locate/process asset `#{resource}`"
	end


	### UNUSED.  I'm generating the base URL via the context_class now.
	### Wrapper function around the Sprockets helper,
	### since it's not clear how best to invoke it.
	def self.asset_url (resource)
		ApplicationController.helpers.asset_url resource
	end


	### Wrapper function around the Sprockets helper,
	### since it's not clear how best to invoke it.
	def self.digest_path (resource)
		## To ensure we have the digested version of the filename,
		## we have to load the Sprockets::Asset into memory.
		Rails.application.assets.find_asset(resource).digest_path
	end
end

# HypeAssets

HypeAssets provides Rails Asset Pipeline integration for Tumult Hype animations.

[Tumult Hype](http://tumult.com/hype/) is a tool for producing animations and
interactive content implemented as HTML5 javascripts and images.  Integrating these
into the
[Rails Asset Pipeline](http://guides.rubyonrails.org/asset_pipeline.html)
would enable serving these resources from a
[CDN](http://guides.rubyonrails.org/asset_pipeline.html#cdns)
and versioning them with
[Digest Fingerprinting](http://guides.rubyonrails.org/asset_pipeline.html#what-is-fingerprinting-and-why-should-i-care-questionmark).
That integration is, unfortunately, difficult to do.
Rails expects that all file references be encapsulated with `asset_path()` calls within
[ERB](http://guides.rubyonrails.org/asset_pipeline.html#javascript-coffeescript-and-erb)
tags, while Tumult Hype produces a minified javascript file containing image filenames
that are each concatenated client-side onto a single base URL.

HypeAssets makes Rails Asset Pipeline integration easy by automatically modifying the foo_hype_generated_script.js file with the correct file references.


## Installation

Add this line to your application‘s Gemfile:

```ruby
gem 'hype_assets'
```

And then execute:

	$ bundle




## Usage

1. Create a folder for your hype animations.   I recommend `app/assets/hype`, but any folder in your assets search path will do.

2. Copy your `foo.hyperesources` folders into that folder.

3. Append a `.hype` extension to your hype scripts:

	```
	$ cd app/assets/hype/foo.hyperesources
	$ mv foo_hype_generated_script.js foo_hype_generated_script.js.hype
	```

	NOTE: Do NOT rename your other javascript files, e.g. HYPE-123.full.min.js.

4. In your HTML, reference your hype animation script with

	```
	<%= javascript_include_tag "foo.hyperesources/foo_hype_generated_script.js" %>
	```


## Contributing

Bug reports, pull requests, and general feedback are welcome on GitHub at https://github.com/nmagedman/hype_assets/issues.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

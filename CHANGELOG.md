# CHANGELOG

## 0.2.0  2016-04-03
* Issue #3: Support HYPE-5xx scripts.  i.e. Avoid relying on specific
  variable names in the hype_generated_script
* Issue #1: Support embedded fonts


## 0.1.3  2016-03-28
* Issue #4: Don't hardcode `assets`.  Get it dynamically from the config.
  OK, we're using Sprockets directly now (not Rails).  The docs
  flag the method we are using (`.context_class`) as deprecated, however
  they don't indicate what should be used instead.


## 0.1.2  2016-03-28
* Issue #4: Don't hardcode `assets`.  Get it dynamically from the config.
  Half-baked solution: We are using Rails rather than Sprockets directly.


## 0.1.1  2016-03-28
* Issue #5: Force a recompile of the `*.hype` file whenever a dependency changes,
  including an external image file and the gem itself.


## 0.1.0  2016-03-20
* Milestone: The basic idea is implemented!
  You can now add your .hyperesource folders into the assets folder,
  renaming the hype_generated_script.js to hype_generated_script.js.hype,
  and we handle the rest: precompiling, registering the handler, and
  Rails pipelining the hype_generated_script.js image references.


## 0.0.3  2016-03-20
* Add the Hype scripts to the the Rails assets precompile array.
  This unfortunately binds us to Rails.   I was hoping to be
  Framework-agnostic, being generically Sprockets, but Sprockets
  alone doesn't seem to have a pre-compile concept, AFAICT.


## 0.0.2  2016-03-17
* Ensure we have the digested version of the filename, by calling find_asset()


## 0.0.1  2016-03-16
* Switch from Sprockets 2.x-style Tilt interface to 3.x-style Rack interface
* Record the version/timestamp in the .js output and the logs


## 0.0.0  2016-03-15
* initial implementation of preprocessor
* registers .hype files with Sprockets

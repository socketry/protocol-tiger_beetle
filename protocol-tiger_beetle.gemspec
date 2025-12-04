# frozen_string_literal: true

require_relative "lib/protocol/tiger_beetle/version"

Gem::Specification.new do |spec|
	spec.name = "protocol-tiger_beetle"
	spec.version = Protocol::TigerBeetle::VERSION
	
	spec.summary = "A pure Ruby client for TigerBeetle, a financial accounting database."
	spec.authors = ["Samuel Williams"]
	spec.license = "MIT"
	
	spec.homepage = "https://github.com/samuel-williams-shopify/protocol-tiger_beetle"
	
	spec.metadata = {
		"source_code_uri" => "https://github.com/samuel-williams-shopify/protocol-tiger_beetle.git",
	}
	
	spec.files = Dir.glob(["{lib,ext}/**/*", "*.md"], File::FNM_DOTMATCH, base: __dir__)
	spec.extensions = ["ext/extconf.rb"]
	
	spec.required_ruby_version = ">= 3.2"
end



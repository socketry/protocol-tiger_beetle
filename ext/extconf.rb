#!/usr/bin/env ruby
# frozen_string_literal: true

require "mkmf"

extension_name = "Protocol_TigerBeetle"

# libaegis doesn't provide pkg-config files, so we need to find it manually
# Try pkg_config first, but if it fails, use Homebrew paths
unless pkg_config("libaegis")
	# Homebrew typically installs to /opt/homebrew on Apple Silicon, /usr/local on Intel
	homebrew_prefixes = ["/opt/homebrew", "/usr/local"]
	libaegis_path = nil
	
	homebrew_prefixes.each do |prefix|
		libaegis_versions = Dir.glob("#{prefix}/Cellar/libaegis/*").sort.reverse
		if libaegis_versions.any?
			libaegis_path = libaegis_versions.first
			break
		end
	end
	
	if libaegis_path && File.exist?("#{libaegis_path}/include/aegis.h")
		libaegis_include = "#{libaegis_path}/include"
		libaegis_lib = "#{libaegis_path}/lib"
		
		# Add include and library paths
		$INCFLAGS << " -I#{libaegis_include}"
		$LDFLAGS << " -L#{libaegis_lib}"
		$LIBS << " -laegis"
	else
		abort "libaegis not found. Please install libaegis: brew install libaegis"
	end
end

# Check for Ruby IO::Buffer API:
have_header("ruby/io/buffer.h")

# Set source files:
$srcs = ["protocol/tiger_beetle/tiger_beetle.c", "protocol/tiger_beetle/checksum.c"]
$VPATH << "$(srcdir)/protocol/tiger_beetle"

append_cflags(["-Wall", "-Wno-unknown-pragmas", "-std=c99"])

if ENV.key?("RUBY_DEBUG")
	$stderr.puts "Enabling debug mode..."
	append_cflags(["-DRUBY_DEBUG", "-O0"])
end

create_header
create_makefile(extension_name)

# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

def build
	ext_path = File.expand_path("ext", __dir__)
	
	Dir.chdir(ext_path) do
		system("ruby ./extconf.rb")
		system("make")
	end
end

def clean
	ext_path = File.expand_path("ext", __dir__)
	
	Dir.chdir(ext_path) do
		system("make clean")
	end
end

# Update the project documentation with the new version number.
#
# @parameter version [String] The new version number.
def after_gem_release_version_increment(version)
	context["releases:update"].call(version)
	context["utopia:project:update"].call
end

# TIGER_BEETLE = "external/tigerbeetle/tigerbeetle"
TIGER_BEETLE = "tigerbeetle"

def setup
	require "fileutils"
	
	FileUtils.mkdir_p("data")
	
	# ./tigerbeetle format --cluster=0 --replica=0 --replica-count=1 --development ./0_0.tigerbeetle
	system(TIGER_BEETLE, "format", "--cluster=0", "--replica=0", "--replica-count=1", "./data/0_0.tigerbeetle")
end

def server
	system(TIGER_BEETLE, "start", "--addresses=127.0.0.1:3000", "./data/0_0.tigerbeetle")
end

def client
	system(TIGER_BEETLE, "client", "localhost:3000")
end

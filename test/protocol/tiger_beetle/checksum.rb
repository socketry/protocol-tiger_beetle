# frozen_string_literal: true

require "protocol/tiger_beetle"

describe Protocol::TigerBeetle::Checksum do
	with ".compute_from_string" do
		it "calculates checksum for empty input" do
			# Test vector from TigerBeetle: empty input
			result = subject.compute_from_string("")
			result_hex = result.bytes.map{|byte| "%02x" % byte}.join
			# Aegis128L MAC output (native little-endian)
			expected = "83cc600dc4e3e7e62d4055826174f149"
			
			expect(result_hex).to be == expected
		end
		
		it "calculates checksum for 16 zero bytes" do
			# Test vector from TigerBeetle: 16 zero bytes
			input = "\x00" * 16
			result = subject.compute_from_string(input)
			result_hex = result.bytes.map{|byte| "%02x" % byte}.join
			# Aegis128L MAC output (native little-endian)
			expected = "f72ad48dd05dd1656133101cd4be3a26"
			
			expect(result_hex).to be == expected
		end
	end
end

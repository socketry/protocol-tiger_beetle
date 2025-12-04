# frozen_string_literal: true

module Protocol
	module TigerBeetle
		# Helper methods for packing and unpacking 128-bit integers using IO::Buffer.
		module Packing
			# Pack a 128-bit integer into a buffer as two 64-bit unsigned integers.
			# @parameter buffer [IO::Buffer] The buffer to write to.
			# @parameter value [Integer] The integer value to pack.
			# @parameter offset [Integer] The offset in the buffer.
			# @returns [Integer] The number of bytes written (16).
			def self.pack_uint128(buffer, value, offset)
				value ||= 0
				# Pack as two 64-bit unsigned integers
				if value >= (1 << 64)
					high = (value >> 64) & 0xFFFFFFFFFFFFFFFF
					low = value & 0xFFFFFFFFFFFFFFFF
					buffer.set_values([:u64, :u64], offset, [low, high])
				else
					buffer.set_values([:u64, :u64], offset, [value, 0])
				end
				16
			end
			
			# Unpack a 128-bit integer from a buffer (two 64-bit unsigned integers).
			# @parameter buffer [IO::Buffer] The buffer to read from.
			# @parameter offset [Integer] The offset in the buffer.
			# @returns [Integer] The integer value.
			def self.unpack_uint128(buffer, offset)
				low, high = buffer.get_values([:u64, :u64], offset)
				(high << 64) | low
			end
		end
	end
end

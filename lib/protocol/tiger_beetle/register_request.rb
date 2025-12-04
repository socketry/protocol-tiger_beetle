# frozen_string_literal: true

module Protocol
	module TigerBeetle
		# RegisterRequest body for the REGISTER operation.
		# Used to register a client with the TigerBeetle cluster.
		class RegisterRequest
			SIZE = 256  # Total size in bytes
			
			# @attribute [Integer] Batch size limit (0 for initial request).
			attr_accessor :batch_size_limit
			
			def initialize(batch_size_limit: 0)
				@batch_size_limit = batch_size_limit
			end
			
			# Pack the register request into a binary buffer.
			# @parameter buffer [IO::Buffer] The buffer to write to.
			# @parameter offset [Integer] The offset in the buffer.
			# @returns [Integer] The number of bytes written.
			def pack(buffer, offset = 0)
				buffer.set_value(:u32, offset, @batch_size_limit)
				# Reserved bytes (252) are already zero from buffer.clear
				
				SIZE
			end
			
			# Unpack a register request from a binary buffer.
			# @parameter buffer [IO::Buffer] The buffer to read from.
			# @parameter offset [Integer] The offset in the buffer.
			# @returns [RegisterRequest] A new RegisterRequest instance.
			def self.unpack(buffer, offset = 0)
				batch_size_limit = buffer.get_value(:u32, offset)
				new(batch_size_limit: batch_size_limit)
			end
		end
	end
end


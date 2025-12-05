# frozen_string_literal: true

module Protocol
	module TigerBeetle
		# Result structure returned for CREATE_TRANSFERS operations.
		# Contains the index of the transfer in the request batch and its result code.
		class CreateTransfersResult
			SIZE = 8 # Total size in bytes (u32 index + u32 result)
			
			# @attribute [Integer] The index of the transfer in the request batch (0-based).
			attr_accessor :index
			
			# @attribute [Integer] The result code (CreateTransferResult enum value).
			attr_accessor :result
			
			def initialize(index = 0, result = 0)
				@index = index
				@result = result
			end
			
			# Unpack a CreateTransfersResult from a binary buffer.
			# @parameter buffer [IO::Buffer] The buffer to read from.
			# @parameter offset [Integer] The offset in the buffer.
			# @returns [CreateTransfersResult] A new CreateTransfersResult instance.
			def self.unpack(buffer, offset = 0)
				index = buffer.get_value(:u32, offset)
				result = buffer.get_value(:u32, offset + 4)
				new(index, result)
			end
		end
	end
end

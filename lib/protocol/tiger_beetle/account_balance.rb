# frozen_string_literal: true

require_relative "packing"

module Protocol
	module TigerBeetle
		# Account balance information returned by GET_ACCOUNT_BALANCES operations.
		class AccountBalance
			SIZE = 128 # Total size in bytes
			
			# @attribute [Integer] Pending debits balance (128-bit).
			attr_accessor :debits_pending
			
			# @attribute [Integer] Posted debits balance (128-bit).
			attr_accessor :debits_posted
			
			# @attribute [Integer] Pending credits balance (128-bit).
			attr_accessor :credits_pending
			
			# @attribute [Integer] Posted credits balance (128-bit).
			attr_accessor :credits_posted
			
			# @attribute [Integer] Timestamp.
			attr_accessor :timestamp
			
			def initialize(**options)
				@debits_pending = 0
				@debits_posted = 0
				@credits_pending = 0
				@credits_posted = 0
				@timestamp = 0
				
				options.each do |key, value|
					setter = "#{key}="
					if respond_to?(setter)
						send(setter, value)
					end
				end
			end
			
			# Unpack an AccountBalance from a binary buffer.
			# @parameter buffer [IO::Buffer] The buffer to read from.
			# @parameter offset [Integer] The offset in the buffer.
			# @returns [AccountBalance] A new AccountBalance instance.
			def self.unpack(buffer, offset = 0)
				balance = allocate
				balance.debits_pending = Packing.unpack_uint128(buffer, offset)
				balance.debits_posted = Packing.unpack_uint128(buffer, offset + 16)
				balance.credits_pending = Packing.unpack_uint128(buffer, offset + 32)
				balance.credits_posted = Packing.unpack_uint128(buffer, offset + 48)
				balance.timestamp = buffer.get_value(:u64, offset + 120)
				
				balance
			end
		end
	end
end

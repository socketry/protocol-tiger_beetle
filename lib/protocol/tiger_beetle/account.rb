# frozen_string_literal: true

require_relative "packing"

module Protocol
	module TigerBeetle
		# Account flags as defined in the TigerBeetle protocol.
		module AccountFlags
			LINKED = 1 << 0
			DEBITS_MUST_NOT_EXCEED_CREDITS = 1 << 1
			CREDITS_MUST_NOT_EXCEED_DEBITS = 1 << 2
			HISTORY = 1 << 3
			IMPORTED = 1 << 4
			CLOSED = 1 << 5
		end
		
		# Result codes for create_accounts operation.
		module CreateAccountResult
			OK = 0
			LINKED_EVENT_FAILED = 1
			LINKED_EVENT_CHAIN_OPEN = 2
			IMPORTED_EVENT_EXPECTED = 22
			IMPORTED_EVENT_NOT_EXPECTED = 23
			TIMESTAMP_MUST_BE_ZERO = 3
			IMPORTED_EVENT_TIMESTAMP_OUT_OF_RANGE = 24
			IMPORTED_EVENT_TIMESTAMP_MUST_NOT_ADVANCE = 25
			RESERVED_FIELD = 4
			RESERVED_FLAG = 5
			ID_MUST_NOT_BE_ZERO = 6
			ID_MUST_NOT_BE_INT_MAX = 7
			EXISTS_WITH_DIFFERENT_FLAGS = 15
			EXISTS_WITH_DIFFERENT_USER_DATA_128 = 16
			EXISTS_WITH_DIFFERENT_USER_DATA_64 = 17
			EXISTS_WITH_DIFFERENT_USER_DATA_32 = 18
			EXISTS_WITH_DIFFERENT_LEDGER = 19
			EXISTS_WITH_DIFFERENT_CODE = 20
			EXISTS = 21
			FLAGS_ARE_MUTUALLY_EXCLUSIVE = 8
			DEBITS_PENDING_MUST_BE_ZERO = 9
			DEBITS_POSTED_MUST_BE_ZERO = 10
			CREDITS_PENDING_MUST_BE_ZERO = 11
			CREDITS_POSTED_MUST_BE_ZERO = 12
			LEDGER_MUST_NOT_BE_ZERO = 13
			CODE_MUST_NOT_BE_ZERO = 14
			IMPORTED_EVENT_TIMESTAMP_MUST_NOT_REGRESS = 26
		end
		
		# Represents an account in TigerBeetle.
		# Accounts hold credits and debits balances and are used in double-entry bookkeeping.
		class Account
			SIZE = 128 # Total size in bytes
			
			# @attribute [Integer] The account ID (128-bit).
			attr_accessor :id
			
			# @attribute [Integer] Pending debits balance (128-bit).
			attr_accessor :debits_pending
			
			# @attribute [Integer] Posted debits balance (128-bit).
			attr_accessor :debits_posted
			
			# @attribute [Integer] Pending credits balance (128-bit).
			attr_accessor :credits_pending
			
			# @attribute [Integer] Posted credits balance (128-bit).
			attr_accessor :credits_posted
			
			# @attribute [Integer] User data (128-bit).
			attr_accessor :user_data_128
			
			# @attribute [Integer] User data (64-bit).
			attr_accessor :user_data_64
			
			# @attribute [Integer] User data (32-bit).
			attr_accessor :user_data_32
			
			# @attribute [Integer] Reserved field (must be zero).
			attr_accessor :reserved
			
			# @attribute [Integer] Ledger number.
			attr_accessor :ledger
			
			# @attribute [Integer] Account code.
			attr_accessor :code
			
			# @attribute [Integer] Account flags.
			attr_accessor :flags
			
			# @attribute [Integer] Timestamp.
			attr_accessor :timestamp
			
			# Initialize a new account.
			# @parameter id [Integer] The account ID (128-bit).
			# @parameter options [Hash] Additional account fields.
			def initialize(id, **options)
				@id = id || 0
				@debits_pending = 0
				@debits_posted = 0
				@credits_pending = 0
				@credits_posted = 0
				@user_data_128 = 0
				@user_data_64 = 0
				@user_data_32 = 0
				@reserved = 0
				@ledger = 0
				@code = 0
				@flags = 0
				@timestamp = 0
				
				options.each do |key, value|
					setter = "#{key}="
					if respond_to?(setter)
						send(setter, value)
					end
				end
			end
			
			# Pack the account into a binary buffer.
			# @parameter buffer [IO::Buffer] The buffer to write to.
			# @parameter offset [Integer] The offset in the buffer.
			# @returns [Integer] The number of bytes written.
			def pack(buffer, offset = 0)
				Packing.pack_uint128(buffer, @id, offset)
				Packing.pack_uint128(buffer, @debits_pending, offset + 16)
				Packing.pack_uint128(buffer, @debits_posted, offset + 32)
				Packing.pack_uint128(buffer, @credits_pending, offset + 48)
				Packing.pack_uint128(buffer, @credits_posted, offset + 64)
				Packing.pack_uint128(buffer, @user_data_128, offset + 80)
				buffer.set_values([:u64], offset + 96, [@user_data_64])
				buffer.set_values([:u32], offset + 104, [@user_data_32])
				buffer.set_values([:u32], offset + 108, [@reserved])
				buffer.set_values([:u32], offset + 112, [@ledger])
				buffer.set_values([:u16], offset + 116, [@code])
				buffer.set_values([:u16], offset + 118, [@flags])
				buffer.set_values([:u64], offset + 120, [@timestamp])
				
				SIZE
			end
			
			# Unpack an account from a binary buffer.
			# @parameter buffer [IO::Buffer] The buffer to read from.
			# @parameter offset [Integer] The offset in the buffer.
			# @returns [Account] A new Account instance.
			def self.unpack(buffer, offset = 0)
				account = allocate
				account.id = Packing.unpack_uint128(buffer, offset)
				account.debits_pending = Packing.unpack_uint128(buffer, offset + 16)
				account.debits_posted = Packing.unpack_uint128(buffer, offset + 32)
				account.credits_pending = Packing.unpack_uint128(buffer, offset + 48)
				account.credits_posted = Packing.unpack_uint128(buffer, offset + 64)
				account.user_data_128 = Packing.unpack_uint128(buffer, offset + 80)
				account.user_data_64 = buffer.get_value(:u64, offset + 96)
				account.user_data_32 = buffer.get_value(:u32, offset + 104)
				account.reserved = buffer.get_value(:u32, offset + 108)
				account.ledger = buffer.get_value(:u32, offset + 112)
				account.code = buffer.get_value(:u16, offset + 116)
				account.flags = buffer.get_value(:u16, offset + 118)
				account.timestamp = buffer.get_value(:u64, offset + 120)
				
				account
			end
		end
	end
end


# frozen_string_literal: true

require_relative "packing"

module Protocol
	module TigerBeetle
		# Transfer flags as defined in the TigerBeetle protocol.
		module TransferFlags
			LINKED = 1 << 0
			PENDING = 1 << 1
			POST_PENDING_TRANSFER = 1 << 2
			VOID_PENDING_TRANSFER = 1 << 3
			BALANCING_DEBIT = 1 << 4
			BALANCING_CREDIT = 1 << 5
			CLOSING_DEBIT = 1 << 6
			CLOSING_CREDIT = 1 << 7
			IMPORTED = 1 << 8
		end
		
		# Result codes for create_transfers operation.
		module CreateTransferResult
			OK = 0
			LINKED_EVENT_FAILED = 1
			LINKED_EVENT_CHAIN_OPEN = 2
			IMPORTED_EVENT_EXPECTED = 56
			IMPORTED_EVENT_NOT_EXPECTED = 57
			TIMESTAMP_MUST_BE_ZERO = 3
			IMPORTED_EVENT_TIMESTAMP_OUT_OF_RANGE = 58
			IMPORTED_EVENT_TIMESTAMP_MUST_NOT_ADVANCE = 59
			RESERVED_FLAG = 4
			ID_MUST_NOT_BE_ZERO = 5
			ID_MUST_NOT_BE_INT_MAX = 6
			EXISTS_WITH_DIFFERENT_FLAGS = 36
			EXISTS_WITH_DIFFERENT_PENDING_ID = 40
			EXISTS_WITH_DIFFERENT_TIMEOUT = 44
			EXISTS_WITH_DIFFERENT_DEBIT_ACCOUNT_ID = 37
			EXISTS_WITH_DIFFERENT_CREDIT_ACCOUNT_ID = 38
			EXISTS_WITH_DIFFERENT_AMOUNT = 39
			EXISTS_WITH_DIFFERENT_USER_DATA_128 = 41
			EXISTS_WITH_DIFFERENT_USER_DATA_64 = 42
			EXISTS_WITH_DIFFERENT_USER_DATA_32 = 43
			EXISTS_WITH_DIFFERENT_LEDGER = 67
			EXISTS_WITH_DIFFERENT_CODE = 45
			EXISTS = 46
			ID_ALREADY_FAILED = 68
			FLAGS_ARE_MUTUALLY_EXCLUSIVE = 7
			DEBIT_ACCOUNT_ID_MUST_NOT_BE_ZERO = 8
			DEBIT_ACCOUNT_ID_MUST_NOT_BE_INT_MAX = 9
			CREDIT_ACCOUNT_ID_MUST_NOT_BE_ZERO = 10
			CREDIT_ACCOUNT_ID_MUST_NOT_BE_INT_MAX = 11
			ACCOUNTS_MUST_BE_DIFFERENT = 12
			PENDING_ID_MUST_BE_ZERO = 13
			PENDING_ID_MUST_NOT_BE_ZERO = 14
			PENDING_ID_MUST_NOT_BE_INT_MAX = 15
			PENDING_ID_MUST_BE_DIFFERENT = 16
			TIMEOUT_RESERVED_FOR_PENDING_TRANSFER = 17
			CLOSING_TRANSFER_MUST_BE_PENDING = 64
			LEDGER_MUST_NOT_BE_ZERO = 19
			CODE_MUST_NOT_BE_ZERO = 20
			DEBIT_ACCOUNT_NOT_FOUND = 21
			CREDIT_ACCOUNT_NOT_FOUND = 22
			ACCOUNTS_MUST_HAVE_THE_SAME_LEDGER = 23
			TRANSFER_MUST_HAVE_THE_SAME_LEDGER_AS_ACCOUNTS = 24
			PENDING_TRANSFER_NOT_FOUND = 25
			PENDING_TRANSFER_NOT_PENDING = 26
			PENDING_TRANSFER_HAS_DIFFERENT_DEBIT_ACCOUNT_ID = 27
			PENDING_TRANSFER_HAS_DIFFERENT_CREDIT_ACCOUNT_ID = 28
			PENDING_TRANSFER_HAS_DIFFERENT_LEDGER = 29
			PENDING_TRANSFER_HAS_DIFFERENT_CODE = 30
			EXCEEDS_PENDING_TRANSFER_AMOUNT = 31
			PENDING_TRANSFER_HAS_DIFFERENT_AMOUNT = 32
			PENDING_TRANSFER_ALREADY_POSTED = 33
			PENDING_TRANSFER_ALREADY_VOIDED = 34
			PENDING_TRANSFER_EXPIRED = 35
			IMPORTED_EVENT_TIMESTAMP_MUST_NOT_REGRESS = 60
			IMPORTED_EVENT_TIMESTAMP_MUST_POSTDATE_DEBIT_ACCOUNT = 61
			IMPORTED_EVENT_TIMESTAMP_MUST_POSTDATE_CREDIT_ACCOUNT = 62
			IMPORTED_EVENT_TIMEOUT_MUST_BE_ZERO = 63
			DEBIT_ACCOUNT_ALREADY_CLOSED = 65
			CREDIT_ACCOUNT_ALREADY_CLOSED = 66
			OVERFLOWS_DEBITS_PENDING = 47
			OVERFLOWS_CREDITS_PENDING = 48
			OVERFLOWS_DEBITS_POSTED = 49
			OVERFLOWS_CREDITS_POSTED = 50
			OVERFLOWS_DEBITS = 51
			OVERFLOWS_CREDITS = 52
			OVERFLOWS_TIMEOUT = 53
			EXCEEDS_CREDITS = 54
			EXCEEDS_DEBITS = 55
		end
		
		# Represents a transfer in TigerBeetle.
		# Transfers move value between accounts using double-entry bookkeeping.
		class Transfer
			SIZE = 128 # Total size in bytes
			
			# @attribute [Integer] The transfer ID (128-bit).
			attr_accessor :id
			
			# @attribute [Integer] The debit account ID (128-bit).
			attr_accessor :debit_account_id
			
			# @attribute [Integer] The credit account ID (128-bit).
			attr_accessor :credit_account_id
			
			# @attribute [Integer] The transfer amount (128-bit).
			attr_accessor :amount
			
			# @attribute [Integer] Pending transfer ID (128-bit, for pending transfers).
			attr_accessor :pending_id
			
			# @attribute [Integer] User data (128-bit).
			attr_accessor :user_data_128
			
			# @attribute [Integer] User data (64-bit).
			attr_accessor :user_data_64
			
			# @attribute [Integer] User data (32-bit).
			attr_accessor :user_data_32
			
			# @attribute [Integer] Timeout for pending transfers.
			attr_accessor :timeout
			
			# @attribute [Integer] Ledger number.
			attr_accessor :ledger
			
			# @attribute [Integer] Transfer code.
			attr_accessor :code
			
			# @attribute [Integer] Transfer flags.
			attr_accessor :flags
			
			# @attribute [Integer] Timestamp.
			attr_accessor :timestamp
			
			# Initialize a new transfer.
			# @parameter id [Integer] The transfer ID (128-bit).
			# @parameter options [Hash] Additional transfer fields.
			def initialize(id, **options)
				@id = id || 0
				@debit_account_id = 0
				@credit_account_id = 0
				@amount = 0
				@pending_id = 0
				@user_data_128 = 0
				@user_data_64 = 0
				@user_data_32 = 0
				@timeout = 0
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
			
			# Pack the transfer into a binary buffer.
			# @parameter buffer [IO::Buffer] The buffer to write to.
			# @parameter offset [Integer] The offset in the buffer.
			# @returns [Integer] The number of bytes written.
			def pack(buffer, offset = 0)
				Packing.pack_uint128(buffer, @id, offset)
				Packing.pack_uint128(buffer, @debit_account_id, offset + 16)
				Packing.pack_uint128(buffer, @credit_account_id, offset + 32)
				Packing.pack_uint128(buffer, @amount, offset + 48)
				Packing.pack_uint128(buffer, @pending_id, offset + 64)
				Packing.pack_uint128(buffer, @user_data_128, offset + 80)
				buffer.set_values([:u64], offset + 96, [@user_data_64])
				buffer.set_values([:u32], offset + 104, [@user_data_32])
				buffer.set_values([:u32], offset + 108, [@timeout])
				buffer.set_values([:u32], offset + 112, [@ledger])
				buffer.set_values([:u16], offset + 116, [@code])
				buffer.set_values([:u16], offset + 118, [@flags])
				buffer.set_values([:u64], offset + 120, [@timestamp])
				
				SIZE
			end
			
			# Unpack a transfer from a binary buffer.
			# @parameter buffer [IO::Buffer] The buffer to read from.
			# @parameter offset [Integer] The offset in the buffer.
			# @returns [Transfer] A new Transfer instance.
			def self.unpack(buffer, offset = 0)
				transfer = allocate
				transfer.id = Packing.unpack_uint128(buffer, offset)
				transfer.debit_account_id = Packing.unpack_uint128(buffer, offset + 16)
				transfer.credit_account_id = Packing.unpack_uint128(buffer, offset + 32)
				transfer.amount = Packing.unpack_uint128(buffer, offset + 48)
				transfer.pending_id = Packing.unpack_uint128(buffer, offset + 64)
				transfer.user_data_128 = Packing.unpack_uint128(buffer, offset + 80)
				transfer.user_data_64 = buffer.get_value(:u64, offset + 96)
				transfer.user_data_32 = buffer.get_value(:u32, offset + 104)
				transfer.timeout = buffer.get_value(:u32, offset + 108)
				transfer.ledger = buffer.get_value(:u32, offset + 112)
				transfer.code = buffer.get_value(:u16, offset + 116)
				transfer.flags = buffer.get_value(:u16, offset + 118)
				transfer.timestamp = buffer.get_value(:u64, offset + 120)
				
				transfer
			end
		end
	end
end


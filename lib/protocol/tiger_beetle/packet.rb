# frozen_string_literal: true

require_relative "native"
require_relative "header"
require_relative "multi_batch"

module Protocol
	module TigerBeetle
		# Operations that use multi-batch encoding
		MULTI_BATCH_OPERATIONS = [
			Operation::CREATE_ACCOUNTS,
			Operation::CREATE_TRANSFERS,
			Operation::LOOKUP_ACCOUNTS,
			Operation::LOOKUP_TRANSFERS,
			Operation::GET_ACCOUNT_TRANSFERS,
			Operation::GET_ACCOUNT_BALANCES,
			Operation::QUERY_ACCOUNTS,
			Operation::QUERY_TRANSFERS,
		].freeze
		
		class Packet
			def initialize(buffer = IO::Buffer.new, header = nil)
				@buffer = buffer
				@header = header
			end
			
			attr_reader :buffer
			attr_accessor :header
			
			def header=(header)
				@header = header
				header.pack(@buffer, 0)
			end
			
		# Round up to the next page boundary.
		def self.page_align(size)
			page_size = IO::Buffer::PAGE_SIZE
			((size + page_size - 1) / page_size) * page_size
		end
		
		# Pack records into the body and update checksums.
		# @parameter records [Array] Records to pack (optional)
		# @parameter body_size [Integer] Fixed body size to use (optional, for pre-filled bodies)
		# @parameter element_size [Integer] Size of each element for multi-batch encoding
		def pack(records = nil, body_size: nil, element_size: nil)
			offset = Header::HEADER_SIZE
			
			if records && !records.empty?
				# Check if this operation uses multi-batch encoding
				if @header && MULTI_BATCH_OPERATIONS.include?(@header.operation)
					# Use multi-batch encoding
					element_size ||= records.first.class::SIZE
					
					# Calculate required size and resize buffer if needed
					trailer_size = MultiBatch.trailer_size(1, element_size)
					required_size = offset + (records.size * element_size) + trailer_size
					if @buffer.size < required_size
						@buffer.resize(Packet.page_align(required_size))
					end
					
					body_written = MultiBatch.encode(@buffer, offset, records, element_size)
					offset += body_written
				else
					# Calculate required size for simple packing
					element_size ||= records.first.class::SIZE
					required_size = offset + (records.size * element_size)
					if @buffer.size < required_size
						@buffer.resize(Packet.page_align(required_size))
					end
					
					# Simple packing without multi-batch trailer
					records.each do |record|
						offset += record.pack(@buffer, offset)
					end
				end
			end
			
			# Use explicit body_size if provided, otherwise use offset from records
			if body_size
				offset = Header::HEADER_SIZE + body_size
			end
			
			self.update_size!(offset)
			self.update_checksums!
			
			return offset
		end
			
			def update_size!(offset)
				@buffer.set_value(:u32, 96, offset)
			end
			
			def update_checksums!
				# Get actual message size from header
				message_size = @buffer.get_value(:u32, 96)
				body_size = message_size - Header::HEADER_SIZE
				
				# 1. First compute checksum_body from the body (after header)
				if body_size > 0
					checksum_body = Checksum.compute_from_buffer(@buffer.slice(Header::HEADER_SIZE, body_size))
				else
					checksum_body = Checksum.compute_from_string("")
				end
				@buffer.set_string(checksum_body, 32)
				
				# 2. Then compute checksum from header bytes 16-255 (which now includes checksum_body)
				checksum = Checksum.compute_from_buffer(@buffer.slice(16, 240))
				@buffer.set_string(checksum, 0)
			end
			
			# Get the actual message size (header + body)
			def size
				@buffer.get_value(:u32, 96)
			end
			
			def data
				@buffer.slice(0, self.size)
			end
		end
	end
end

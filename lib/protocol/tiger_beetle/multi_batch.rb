# frozen_string_literal: true

module Protocol
	module TigerBeetle
		# Multi-batch encoding for TigerBeetle operations.
		# The body consists of:
		# - Payload: the actual records
		# - Trailer: batch metadata at the end, padded to element_size
		#   - Padding (0xFFFF repeated)
		#   - element_count for each batch (u16, in reverse order)
		#   - postamble: batch_count (u16)
		module MultiBatch
			# Calculate the trailer size for the given number of batches.
			# @parameter batch_count [Integer] The number of batches.
			# @parameter element_size [Integer] The size of each element (e.g., 128 for Account).
			# @returns [Integer] The trailer size in bytes, padded to element_size.
			def self.trailer_size(batch_count, element_size)
				# Each batch gets a u16 element_count, plus a u16 postamble
				trailer_unpadded = (batch_count * 2) + 2
				
				# Pad to element_size
				if element_size == 0
					trailer_unpadded
				else
					((trailer_unpadded + element_size - 1) / element_size) * element_size
				end
			end
			
			# Encode a single batch of records using multi-batch encoding.
			# @parameter buffer [IO::Buffer] The buffer to write to.
			# @parameter offset [Integer] The starting offset in the buffer.
			# @parameter records [Array] The records to encode.
			# @parameter element_size [Integer] The size of each element.
			# @returns [Integer] The total number of bytes written (payload + trailer).
			def self.encode(buffer, offset, records, element_size)
				# Write the payload (records)
				payload_offset = offset
				records.each do |record|
					record.pack(buffer, payload_offset)
					payload_offset += element_size
				end
				
				payload_size = records.size * element_size
				element_count = records.size
				batch_count = 1
				
				# Calculate trailer
				trailer_size = self.trailer_size(batch_count, element_size)
				trailer_offset = offset + payload_size
				
			# Write padding (0xFF bytes, which is 0xFFFF as u16 values)
			padding_size = trailer_size - 4 # 4 bytes for element_count + postamble
			buffer.set_string("\xFF" * padding_size, trailer_offset)
				
				# Write element_count for batch 0 (u16, little-endian)
				buffer.set_value(:u16, trailer_offset + padding_size, element_count)
				
				# Write postamble (batch_count as u16, little-endian)
				buffer.set_value(:u16, trailer_offset + padding_size + 2, batch_count)
				
				payload_size + trailer_size
			end
			
			# Decode records from a multi-batch encoded buffer.
			# @parameter buffer [IO::Buffer] The buffer to read from.
			# @parameter offset [Integer] The starting offset in the buffer.
			# @parameter body_size [Integer] The total size of the body (payload + trailer).
			# @parameter element_size [Integer] The size of each element.
			# @parameter record_class [Class] The class to instantiate records with (must have an unpack method).
			# @returns [Array] Array of decoded records.
			def self.decode(buffer, offset, body_size, element_size, record_class)
				return [] if body_size < 2 # Need at least 2 bytes for postamble
				
				# Read postamble (batch_count) from the end
				postamble_offset = offset + body_size - 2
				batch_count = buffer.get_value(:u16, postamble_offset)
				
				return [] if batch_count == 0
				
				# Calculate trailer size
				trailer_size = self.trailer_size(batch_count, element_size)
				
				# Read element counts from trailer
				# Element counts are stored before the postamble: [batch N] ... [batch 0] [postamble]
				element_counts_offset = postamble_offset - (batch_count * 2)
				
				# Sum up all element counts from all batches
				total_elements = 0
				batch_count.times do |i|
					count = buffer.get_value(:u16, element_counts_offset + (i * 2))
					total_elements += count
				end
				
				# Calculate payload size (should match total_elements * element_size)
				payload_size = total_elements * element_size
				
				# There may be padding between payload and trailer_items if element_size == 1
				# For element_size >= 2 (like 128), payload is already u16-aligned
				# Verify the body size matches
				expected_body_size = payload_size + trailer_size
				if body_size != expected_body_size && element_size == 1
					# Handle byte padding between payload and trailer
					trailer_padding_size = body_size - expected_body_size
					# Adjust payload_size to account for padding
					payload_size = body_size - trailer_size
				end
				
				# Decode records from payload
				records = []
				payload_offset = offset
				total_elements.times do
					record = record_class.unpack(buffer, payload_offset)
					records << record
					payload_offset += element_size
				end
				
				records
			end
		end
	end
end


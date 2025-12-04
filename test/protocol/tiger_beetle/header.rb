# frozen_string_literal: true

require "protocol/tiger_beetle"

describe Protocol::TigerBeetle::Header do
	let(:header_size) {256}
	
	with ".unpack" do
		it "unpacks a minimal header buffer" do
			buffer = IO::Buffer.new(header_size)
			buffer.clear
			
			# Set some known values at their correct offsets:
			# size at offset 96 (u32)
			buffer.set_value(:u32, 96, header_size)
			# command at offset 114 (u8)
			buffer.set_value(:U8, 114, 8) # REPLY command
			
			header = Protocol::TigerBeetle::Header.unpack(buffer)
			
			expect(header.size).to be == header_size
			expect(header.command).to be == 8
		end
		
		it "unpacks u128 fields in little-endian order" do
			buffer = IO::Buffer.new(header_size)
			buffer.clear
			
			# Set checksum at offset 0 as two u64s in little-endian:
			# low word first (offset 0), high word second (offset 8)
			low_word = 0x0123456789ABCDEF
			high_word = 0xFEDCBA9876543210
			buffer.set_value(:u64, 0, low_word)
			buffer.set_value(:u64, 8, high_word)
			
			# Set cluster at offset 80:
			cluster_low = 0x1111111111111111
			cluster_high = 0x2222222222222222
			buffer.set_value(:u64, 80, cluster_low)
			buffer.set_value(:u64, 88, cluster_high)
			
			header = Protocol::TigerBeetle::Header.unpack(buffer)
			
			# Little-endian u128: high << 64 | low
			expected_checksum = (high_word << 64) | low_word
			expected_cluster = (cluster_high << 64) | cluster_low
			
			expect(header.checksum).to be == expected_checksum
			expect(header.cluster).to be == expected_cluster
		end
		
		it "unpacks all header fields correctly" do
			buffer = IO::Buffer.new(header_size)
			buffer.clear
			
			# Set values at their offsets:
			buffer.set_value(:u32, 96, 512)   # size
			buffer.set_value(:u32, 100, 1)    # epoch
			buffer.set_value(:u32, 104, 2)    # view
			buffer.set_value(:u32, 108, 3)    # release
			buffer.set_value(:u16, 112, 4)    # protocol
			buffer.set_value(:U8, 114, 5)     # command
			buffer.set_value(:U8, 115, 6)     # replica
			
			header = Protocol::TigerBeetle::Header.unpack(buffer)
			
			expect(header.size).to be == 512
			expect(header.epoch).to be == 1
			expect(header.view).to be == 2
			expect(header.release).to be == 3
			expect(header.protocol).to be == 4
			expect(header.command).to be == 5
			expect(header.replica).to be == 6
		end
	end
end


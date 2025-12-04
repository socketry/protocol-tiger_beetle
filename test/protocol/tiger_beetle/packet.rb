# frozen_string_literal: true

require "protocol/tiger_beetle"

describe Protocol::TigerBeetle::Packet do
	let(:header_size) {Protocol::TigerBeetle::Header::HEADER_SIZE}
	
	with "#initialize" do
		it "can be created with a buffer" do
			buffer = IO::Buffer.new(header_size)
			packet = Protocol::TigerBeetle::Packet.new(buffer)
			
			expect(packet).to be_a(Protocol::TigerBeetle::Packet)
		end
		
		it "can be created without a buffer" do
			packet = Protocol::TigerBeetle::Packet.new
			
			expect(packet).to be_a(Protocol::TigerBeetle::Packet)
		end
	end
	
	with "#header" do
		it "returns the header passed in constructor" do
			buffer = IO::Buffer.new(header_size)
			buffer.clear
			buffer.set_value(:u32, 96, header_size)
			buffer.set_value(:U8, 114, 8) # REPLY command
			
			header = Protocol::TigerBeetle::Header.unpack(buffer)
			packet = Protocol::TigerBeetle::Packet.new(buffer, header)
			
			expect(packet.header).to be_a(Protocol::TigerBeetle::Header)
			expect(packet.header.size).to be == header_size
			expect(packet.header.command).to be == 8
		end
	end
	
	with "#update_size!" do
		it "updates the size field in the buffer" do
			buffer = IO::Buffer.new(header_size)
			buffer.clear
			
			packet = Protocol::TigerBeetle::Packet.new(buffer)
			packet.update_size!(512)
			
			expect(buffer.get_value(:u32, 96)).to be == 512
		end
	end
	
	with "#update_checksums!" do
		it "computes and writes checksums for header-only packet" do
			buffer = IO::Buffer.new(header_size)
			buffer.clear
			buffer.set_value(:u32, 96, header_size) # size = header only
			
			packet = Protocol::TigerBeetle::Packet.new(buffer)
			packet.update_checksums!
			
			# Checksums should be non-zero after computation
			checksum_low = buffer.get_value(:u64, 0)
			checksum_high = buffer.get_value(:u64, 8)
			checksum = (checksum_high << 64) | checksum_low
			
			expect(checksum).not.to be == 0
		end
		
		it "computes checksum_body from body data" do
			total_size = header_size + 128
			buffer = IO::Buffer.new(total_size)
			buffer.clear
			buffer.set_value(:u32, 96, total_size)
			
			# Write some body data
			buffer.set_string("A" * 128, header_size)
			
			packet = Protocol::TigerBeetle::Packet.new(buffer)
			packet.update_checksums!
			
			# checksum_body should be non-zero
			checksum_body_low = buffer.get_value(:u64, 32)
			checksum_body_high = buffer.get_value(:u64, 40)
			checksum_body = (checksum_body_high << 64) | checksum_body_low
			
			expect(checksum_body).not.to be == 0
		end
		
		it "produces different checksums for different body data" do
			total_size = header_size + 128
			
			# First packet with body "AAAA..."
			buffer1 = IO::Buffer.new(total_size)
			buffer1.clear
			buffer1.set_value(:u32, 96, total_size)
			buffer1.set_string("A" * 128, header_size)
			packet1 = Protocol::TigerBeetle::Packet.new(buffer1)
			packet1.update_checksums!
			
			# Second packet with body "BBBB..."
			buffer2 = IO::Buffer.new(total_size)
			buffer2.clear
			buffer2.set_value(:u32, 96, total_size)
			buffer2.set_string("B" * 128, header_size)
			packet2 = Protocol::TigerBeetle::Packet.new(buffer2)
			packet2.update_checksums!
			
			# Both checksums should differ
			checksum1 = buffer1.get_value(:u64, 0)
			checksum2 = buffer2.get_value(:u64, 0)
			
			expect(checksum1).not.to be == checksum2
		end
	end
end

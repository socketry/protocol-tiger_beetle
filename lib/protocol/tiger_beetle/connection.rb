# frozen_string_literal: true

require "socket"
require_relative "packet"

module Protocol
	module TigerBeetle
		class Connection
			HEADER_SIZE = Header::HEADER_SIZE
			
			# Map command ID to header class
			HEADER_TYPES = {
				Command::REQUEST => Request,
				Command::REPLY => Reply,
			}.freeze
			
			def initialize(io)
				@io = io
				@buffer = IO::Buffer.new(HEADER_SIZE)
			end
			
			def close
				if io = @io
					@io = nil
					io.close
				end
			end
			
			def read
				size = @buffer.slice(0, HEADER_SIZE).read(@io, HEADER_SIZE)
				
				size = @buffer.get_value(:u32, 96)
				command = @buffer.get_value(:U8, 114)
				
				body_size = size - HEADER_SIZE
				if body_size > 0
					if @buffer.size < size
						@buffer.resize(size)
					end
					@buffer.slice(HEADER_SIZE, body_size).read(@io, body_size)
				end
				
				header_class = HEADER_TYPES.fetch(command, Header)
				header = header_class.unpack(@buffer, 0)
				
				Packet.new(@buffer.slice(0, size), header)
			end
			
			def write(packet)
				data = packet.data
				data.write(@io, data.size)
			end
		end
	end
end
# frozen_string_literal: true

require_relative "native"

module Protocol
	module TigerBeetle
		# VSR Command codes
		module Command
			RESERVED = 0
			REQUEST = 5
			REPLY = 8
		end
		
		# TigerBeetle Operation codes (from vsr.zig)
		module Operation
			RESERVED = 0
			ROOT = 1
			REGISTER = 2
			RECONFIGURE = 3
			PULSE = 4
			UPGRADE = 5
			# State machine operations start at 128
			CREATE_ACCOUNTS = 128 + 10      # 138
			CREATE_TRANSFERS = 128 + 11     # 139
			LOOKUP_ACCOUNTS = 128 + 12      # 140
			LOOKUP_TRANSFERS = 128 + 13     # 141
			GET_ACCOUNT_TRANSFERS = 128 + 14
			GET_ACCOUNT_BALANCES = 128 + 15
			QUERY_ACCOUNTS = 128 + 16
			QUERY_TRANSFERS = 128 + 17
		end
		
		# Base header class - common fields for all message types
		class Header
			HEADER_SIZE = 256
			
			# Base header fields (offset 0-115)
			BASE_HEADER = [
				:u64, :u64, # checksum (offset 0)
				:u64, :u64, # checksum_padding (offset 16)
				:u64, :u64, # checksum_body (offset 32)
				:u64, :u64, # checksum_body_padding (offset 48)
				:u64, :u64, # nonce_reserved (offset 64)
				:u64, :u64, # cluster (offset 80)
				:u32, # size (offset 96)
				:u32, # epoch (offset 100)
				:u32, # view (offset 104)
				:u32, # release (offset 108)
				:u16, # protocol (offset 112)
				:U8, # command (offset 114)
				:U8, # replica (offset 115)
			]
			
			def self.unpack(buffer, offset = 0)
				values = buffer.get_values(BASE_HEADER, offset)
				
				# Little-endian: low word first, then high word
				checksum = values[1] << 64 | values[0]
				checksum_body = values[5] << 64 | values[4]
				cluster = values[11] << 64 | values[10]
				size = values[12]
				epoch = values[13]
				view = values[14]
				release = values[15]
				protocol = values[16]
				command = values[17]
				replica = values[18]
				
				new(checksum, checksum_body, cluster, size, epoch, view, release, protocol, command, replica)
			end
			
			def initialize(checksum, checksum_body, cluster, size, epoch, view, release, protocol, command, replica)
				@checksum = checksum
				@checksum_body = checksum_body
				@cluster = cluster
				@size = size
				@epoch = epoch
				@view = view
				@release = release
				@protocol = protocol
				@command = command
				@replica = replica
			end
			
			attr_accessor :checksum
			attr_accessor :checksum_body
			attr_accessor :cluster
			attr_accessor :size
			attr_accessor :epoch
			attr_accessor :view
			attr_accessor :release
			attr_accessor :protocol
			attr_accessor :command
			attr_accessor :replica
			
			def pack(buffer, offset = 0)
				values = [
					@checksum & 0xFFFFFFFFFFFFFFFF,
					@checksum >> 64,
					0, 0,
					@checksum_body & 0xFFFFFFFFFFFFFFFF,
					@checksum_body >> 64,
					0, 0,
					0, 0,  # nonce_reserved
					@cluster & 0xFFFFFFFFFFFFFFFF,
					@cluster >> 64,
					@size,
					@epoch,
					@view,
					@release,
					@protocol,
					@command,
					@replica,
				]
				
				buffer.set_values(BASE_HEADER, offset, values)
			end
		end
		
		# Request header - includes client request fields (offsets 128-196)
		class Request < Header
			# Request-specific fields
			REQUEST_FIELDS = [
				:u64, :u64, # parent (offset 128)
				:u64, :u64, # parent_padding (offset 144)
				:u64, :u64, # client (offset 160)
				:u64,       # session (offset 176)
				:u64,       # timestamp (offset 184) - reserved, must be 0
				:u32,       # request (offset 192)
				:U8,        # operation (offset 196)
			]
			
			def self.with(cluster: 0, release: 0, client_id:, session: 0, request_number: 0, operation:, parent: 0)
				new(0, 0, cluster, HEADER_SIZE, 0, 0, release, 0, Command::REQUEST, 0, parent, client_id, session, request_number, operation)
			end
			
			def self.unpack(buffer, offset = 0)
				# Unpack base header fields
				base_values = buffer.get_values(BASE_HEADER, offset)
				checksum = base_values[1] << 64 | base_values[0]
				checksum_body = base_values[5] << 64 | base_values[4]
				cluster = base_values[11] << 64 | base_values[10]
				size = base_values[12]
				epoch = base_values[13]
				view = base_values[14]
				release = base_values[15]
				protocol = base_values[16]
				command = base_values[17]
				replica = base_values[18]
				
				# Unpack request-specific fields
				values = buffer.get_values(REQUEST_FIELDS, offset + 128)
				parent = values[1] << 64 | values[0]
				client_id = values[5] << 64 | values[4]
				session = values[6]
				request_number = values[8]
				operation = values[9]
				
				new(checksum, checksum_body, cluster, size, epoch, view, release, protocol, command, replica, parent, client_id, session, request_number, operation)
			end
			
			def initialize(checksum, checksum_body, cluster, size, epoch, view, release, protocol, command, replica, parent, client_id, session, request_number, operation)
				super(checksum, checksum_body, cluster, size, epoch, view, release, protocol, command, replica)
				@parent = parent
				@client_id = client_id
				@session = session
				@request_number = request_number
				@operation = operation
			end
			
			attr_accessor :parent
			attr_accessor :client_id
			attr_accessor :session
			attr_accessor :request_number
			attr_accessor :operation
			
			def pack(buffer, offset = 0)
				super(buffer, offset)
				
				values = [
					@parent & 0xFFFFFFFFFFFFFFFF,
					@parent >> 64,
					0, 0,  # parent_padding
					@client_id & 0xFFFFFFFFFFFFFFFF,
					@client_id >> 64,
					@session,
					0,  # timestamp (reserved)
					@request_number,
					@operation,
				]
				
				buffer.set_values(REQUEST_FIELDS, offset + 128, values)
			end
		end
		
		# Reply header - includes server reply fields (offsets 128-216)
		class Reply < Header
			# Reply-specific fields
			REPLY_FIELDS = [
				:u64, :u64, # request_checksum (offset 128)
				:u64, :u64, # request_checksum_padding (offset 144)
				:u64, :u64, # context (offset 160) - becomes parent for next request
			]
			
			COMMIT_OFFSET = 216
			
			def self.unpack(buffer, offset = 0)
				# Unpack base header fields
				base_values = buffer.get_values(BASE_HEADER, offset)
				checksum = base_values[1] << 64 | base_values[0]
				checksum_body = base_values[5] << 64 | base_values[4]
				cluster = base_values[11] << 64 | base_values[10]
				size = base_values[12]
				epoch = base_values[13]
				view = base_values[14]
				release = base_values[15]
				protocol = base_values[16]
				command = base_values[17]
				replica = base_values[18]
				
				# Unpack reply-specific fields
				values = buffer.get_values(REPLY_FIELDS, offset + 128)
				request_checksum = values[1] << 64 | values[0]
				context = values[5] << 64 | values[4]
				commit = buffer.get_value(:u64, offset + COMMIT_OFFSET)
				
				new(checksum, checksum_body, cluster, size, epoch, view, release, protocol, command, replica, request_checksum, context, commit)
			end
			
			def initialize(checksum, checksum_body, cluster, size, epoch, view, release, protocol, command, replica, request_checksum, context, commit)
				super(checksum, checksum_body, cluster, size, epoch, view, release, protocol, command, replica)
				@request_checksum = request_checksum
				@context = context
				@commit = commit
			end
			
			attr_accessor :request_checksum
			attr_accessor :context
			attr_accessor :commit
			
			# Alias for clarity
			alias_method :session, :commit
		end
	end
end

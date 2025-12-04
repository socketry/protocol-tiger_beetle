#!/usr/bin/env ruby
# frozen_string_literal: true

require "securerandom"
require "io/nonblock"
require "async/clock"

require_relative "config/environment"
require_relative "lib/protocol/tiger_beetle"

# Encode version triple: patch | (minor << 8) | (major << 16)
def release_version(major, minor, patch)
	patch | (minor << 8) | (major << 16)
end

RELEASE = release_version(0, 16, 66)  # Match bin/tigerbeetle version
BATCH_SIZE = 8
BENCHMARK_DURATION = 5.0  # seconds

stream = TCPSocket.new("localhost", 3000)
stream.nonblock = false

connection = Protocol::TigerBeetle::Connection.new(stream)
client_id = SecureRandom.random_number(2**128)
request_number = 0

packet = Protocol::TigerBeetle::Packet.new

# Register the client
request = Protocol::TigerBeetle::Request.with(
	cluster: 0,
	client_id: client_id,
	session: 0,
	request_number: request_number,
	operation: Protocol::TigerBeetle::Operation::REGISTER,
	parent: 0,
	release: RELEASE,
)

packet.header = request
packet.pack([Protocol::TigerBeetle::RegisterRequest.new])
connection.write(packet)

register_reply = connection.read
session = register_reply.header.session
parent = register_reply.header.context
puts "Registered! Session: #{session}"

# Use existing accounts 1 and 2 (ledger: 700, code: 10)
debit_account_id = 1
credit_account_id = 2

$transfer_id = SecureRandom.random_number(2**64) # Start with a random base

def generate_transfers(batch_size, debit_account_id, credit_account_id)
	transfers = []
	batch_size.times do
		$transfer_id += 1
		transfer = Protocol::TigerBeetle::Transfer.new(
			$transfer_id,
			debit_account_id: debit_account_id,
			credit_account_id: credit_account_id,
			amount: rand(1..10_000),
			ledger: 700,
			code: 10,
		)
		transfers << transfer
	end
	transfers
end

puts "Benchmarking with batches of #{BATCH_SIZE} transfers for ~#{BENCHMARK_DURATION}s..."

total_transfers = 0
batch_count = 0
clock = Async::Clock.start

while clock.total < BENCHMARK_DURATION
	# Generate fresh transfer IDs for each batch
	transfers = generate_transfers(BATCH_SIZE, debit_account_id, credit_account_id)
	
	request_number += 1
	request = Protocol::TigerBeetle::Request.with(
		cluster: 0,
		client_id: client_id,
		session: session,
		request_number: request_number,
		operation: Protocol::TigerBeetle::Operation::CREATE_TRANSFERS,
		parent: parent,
		release: RELEASE,
	)
	
	packet.header = request
	packet.pack(transfers)
	connection.write(packet)
	
	reply = connection.read
	parent = reply.header.context
	
	total_transfers += BATCH_SIZE
	batch_count += 1
end

elapsed = clock.total
rate = total_transfers / elapsed

puts ""
puts "Results:"
puts "  Batches sent: #{batch_count}"
puts "  Total transfers: #{total_transfers}"
puts "  Elapsed time: #{elapsed.round(3)}s"
puts "  Rate: #{rate.round(0)} transfers/second"

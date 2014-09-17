require_relative 'spec_helper'

require 'socket'

describe 'rspamd legacy (spamd) client protocol', rspamd: :legacy do
	describe 'normal process' do
		subject do
			TCPSocket.new('localhost', 41333)
		end

		let :spam do
			File.read('spec/support/spam1.eml')
		end

		it 'should respond to ping' do
			subject.puts 'PING RSPAMC/1.1'
			subject.puts
			expect(subject.read).to include('PONG')
		end

		it 'should check an email' do
			subject.puts 'CHECK RSPAMC/1.1'
			subject.puts "Content-Length: #{spam.length}"
			subject.puts
			subject.write spam

			#puts subject.read
			expect(subject.read).to include('Metric: ')
		end
	end
end

require 'faraday'

describe 'rspamd HTTP client protocol', rspamd: :server do
	let :spam do
		File.read('spec/support/spam1.eml')
	end

	describe 'normal process' do
		subject do
			Faraday.new(:url => 'http://localhost:11333') do |faraday|
				faraday.options[:timeout] = 2
				faraday.adapter Faraday.default_adapter
			end
		end

		it 'should ping' do
			p subject.get '/ping'
		end

		it 'should score email' do
			resp = subject.post do |req|
				req.body = spam
			end

			expect(resp.body).to include('Metric: ')
		end
	end

	describe 'controller process' do
		subject do
			Faraday.new(:url => 'http://localhost:11334') do |faraday|
				faraday.options[:timeout] = 2
				faraday.adapter Faraday.default_adapter
				faraday.headers['Host'] = 'localhost'
				faraday.headers['Accept'] = 'application/json'
			end
		end

		it 'should' do
			p subject
			resp = subject.get '/stat'
			p resp
			p resp.status
			p resp.body
		end
	end
end


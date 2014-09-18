require_relative 'spec_helper'

require 'socket'
require 'excon'

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

describe 'rspamd HTTP client protocol', rspamd: :server do
	let :spam do
		File.read('spec/support/spam1.eml')
	end

	let :normal do
		Excon.new('http://localhost:11333', read_timeout: 4)
	end

	let :control do
		Excon.new('http://localhost:11334', read_timeout: 4)
	end

	describe 'normal process' do

		it 'should score email' do
			# Ip: 123.123.123.123
			# User: fdas@efa.com
			# From: afds@fda.com
			# Deliver-To: test
			# Rcpt: dfa@fas.com
			resp = normal.get headers: {
				'Command' => 'symbols',
				'User' => 'fdas@efa.com',
				'Deliver-To' => 'fads',
				'Ip' => '192.168.0.1', # verify IP with SPF - R_SPF_SOFTFAIL
				'From' => 'bfalsdh@compuware.com', # verify sender with email - FORGED_SENDER
				'Rcpt' => 'dfas@whatclinic.com' # verify recipient with email - FORGED_RECIPIENTS
			}, body: spam

			puts resp.body
			expect(resp.body).to include(
				'Metric: ',
				'Symbol: R_SPF_SOFTFAIL',
				'Symbol: FORGED_RECIPIENTS',
				'Symbol: FORGED_SENDER'
			)

			puts rspamd.log_file.to_s
		end
	end

	describe 'controller process' do
		it 'should provide stats' do
			# GET / HTTP/1.0
			# Command: stat
			resp = control.get headers: {'Command' => 'stat'}
			expect(resp.body).to include 'Messages scanned:'
		end

		it 'should learn spam' do
			# GET / HTTP/1.0
			# Command: learn_spam
			# Content-Length: 414
			# Classifier: bayes
			resp = control.get headers: { 'Command' => 'learn_spam', 'Classifier' => 'bayes' }, body: spam
			expect(resp.status).to eq 200

			# should be spam by bayes
			resp = normal.post body: spam
			expect(resp.body).to include 'Symbol: BAYES_SPAM'
			expect(resp.body).not_to include 'Symbol: BAYES_HAM'
		end

		it 'should learn ham' do
			# GET / HTTP/1.0
			# Command: learn_ham
			# Content-Length: 414
			# Classifier: bayes
			resp = control.get headers: { 'Command' => 'learn_ham', 'Classifier' => 'bayes' }, body: spam
			expect(resp.status).to eq 200

			# should be spam by bayes
			resp = normal.post body: spam
			expect(resp.body).not_to include 'Symbol: BAYES_SPAM'
			expect(resp.body).to include 'Symbol: BAYES_HAM'
		end
	end
end


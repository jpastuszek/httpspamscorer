require_relative 'spec_helper'

require 'socket'
require 'excon'
require 'json'

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
			# POST /check HTTP/1.0
			# Content-Length: 414
			# From: afds@fda.com
			# Hostname: fsda
			# Deliver-To: test
			# User: fdas@efa.com
			# Ip: 123.123.123.123
			# Rcpt: dfa@fas.com
			# Helo: fdas

			resp = normal.post path: '/check',
			headers: {
				'Hostname' => 'fdsa', # SMTP hostname
				'User' => 'fdas@efa.com',
				'Deliver-To' => 'fads',
				'Helo' => 'fdsa', # verify SMTP hello message - HFILTER_HELO_NOT_FQDN
				'Ip' => '192.168.0.1', # verify IP with SPF - R_SPF_SOFTFAIL
				'From' => 'bfalsdh@compuware.com', # verify sender with email - FORGED_SENDER
				'Rcpt' => 'dfas@whatclinic.com' # verify recipient with email - FORGED_RECIPIENTS
			}, body: spam

			#pp JSON.parse(resp.body)

			expect(JSON.parse(resp.body)).to a_collection_including(
				'default' => a_collection_including(
					'is_spam' => false,
					'is_skipped' => false,
					'score' => an_instance_of(Float),
					'required_score' => an_instance_of(Float),
					'action' => 'no action',
					'HFILTER_HELO_NOT_FQDN' => a_collection_including('score' => an_instance_of(Float)),
					'FORGED_SENDER' => a_collection_including('score' => an_instance_of(Float)),
					'FORGED_RECIPIENTS' => a_collection_including('score' => an_instance_of(Float))
				)
			)

			#puts rspamd.log_file.to_s
		end
	end

	describe 'controller process' do
		it 'should provide stats' do
			# GET /stat HTTP/1.0
			resp = control.get path: '/stat'

			#pp JSON.parse(resp.body)

			expect(JSON.parse(resp.body)).to a_collection_including(
				'scanned' => an_instance_of(Fixnum),
				'ham_count' => an_instance_of(Fixnum),
				'spam_count' => an_instance_of(Fixnum),
				'learned' => an_instance_of(Fixnum)
			)
		end

		it 'should learn spam' do
			# POST /learnspam HTTP/1.0
			# Content-Length: 414

			resp = control.post path: '/learnspam', body: spam
			expect(resp.status).to eq 200
			expect(JSON.parse(resp.body)).to eq({'success' => true})

			# should be spam by bayes
			resp = normal.post path: '/check', body: spam

			expect(JSON.parse(resp.body)).to a_collection_including(
				'default' => a_collection_including(
					'BAYES_SPAM' => a_collection_including('score' => an_instance_of(Float)),
				)
			)

			expect(JSON.parse(resp.body)).not_to a_collection_including(
				'default' => a_collection_including(
					'BAYES_HAM' => a_collection_including('score' => an_instance_of(Float)),
				)
			)
		end

		it 'should learn ham' do
			# POST /learnham HTTP/1.0
			# Content-Length: 414

			resp = control.post path: '/learnham', body: spam
			expect(resp.status).to eq 200
			expect(JSON.parse(resp.body)).to eq({'success' => true})

			# should be spam by bayes
			resp = normal.post path: '/check', body: spam

			expect(JSON.parse(resp.body)).not_to a_collection_including(
				'default' => a_collection_including(
					'BAYES_SPAM' => a_collection_including('score' => an_instance_of(Float)),
				)
			)

			expect(JSON.parse(resp.body)).to a_collection_including(
				'default' => a_collection_including(
					'BAYES_HAM' => a_collection_including('score' => an_instance_of(Float)),
				)
			)
		end
	end
end


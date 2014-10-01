require_relative '../spec_helper'

feature 'RSpamd HTTP API', with: :spam_examples, rspamd: :server do
	context 'normal process' do
		subject do
			normal_client
		end

		scenario 'scoring e-mail' do
			# POST /check HTTP/1.0
			# Content-Length: 414
			# From: afds@fda.com
			# Hostname: fsda
			# Deliver-To: test
			# User: fdas@efa.com
			# Ip: 123.123.123.123
			# Rcpt: dfa@fas.com
			# Helo: fdas

			when_i_make_post_request_to '/check', with_headers: {
				'Hostname' => 'fdsa', # SMTP hostname - HFILTER_HELO_NOT_FQDN
				'User' => 'fdas@efa.com', # for logging
				'Deliver-To' => 'fads',
				'Helo' => 'fdsa', # verify SMTP hello message
				'Ip' => '192.168.0.1', # verify IP with SPF - R_SPF_SOFTFAIL and backlists (Spamhouse etc.)
				'From' => 'bfalsdh@compuware.com', # verify sender with email - FORGED_SENDER
				'Rcpt' => 'dfas@whatclinic.com' # verify recipient with email - FORGED_RECIPIENTS
			}, with_body: spam.to_s

			then_response_should_contain_json_with a_collection_including(
				'default' => a_collection_including(
					'is_spam' => false,
					'is_skipped' => false,
					'score' => an_instance_of(Float),
					'required_score' => an_instance_of(Float),
					'action' => an_instance_of(String),
					'HFILTER_HELO_NOT_FQDN' => a_collection_including('score' => an_instance_of(Float)),
					'FORGED_SENDER' => a_collection_including('score' => an_instance_of(Float)),
					'FORGED_RECIPIENTS' => a_collection_including('score' => an_instance_of(Float))
				)
			)
		end
	end

	context 'controller process' do
		subject do
			control_client
		end

		scenario 'getting stats' do
			# GET /stat HTTP/1.0

			when_i_make_get_request_to '/stat'

			then_response_should_contain_json_with a_collection_including(
				'scanned' => an_instance_of(Fixnum),
				'ham_count' => an_instance_of(Fixnum),
				'spam_count' => an_instance_of(Fixnum),
				'learned' => an_instance_of(Fixnum)
			)
		end

		scenario 'learing e-mail as spam' do
			# POST /learnspam HTTP/1.0
			# Content-Length: 414

			when_i_make_post_request_to '/learnspam', with_body: spam.to_s

			then_response_status_should_be 200
			then_response_should_contain_json_with an_object_eq_to('success' => true)

			# should be spam by bayes
			when_i_make_post_request_to '/check', with_body: spam.to_s, with_client: normal_client

			then_response_should_contain_json_with a_collection_including(
				'default' => a_collection_including(
					'BAYES_SPAM' => a_collection_including('score' => an_instance_of(Float)),
				)
			)
			then_response_should_contain_json_without a_collection_including(
				'default' => a_collection_including(
					'BAYES_HAM' => a_collection_including('score' => an_instance_of(Float)),
				)
			)
		end

		scenario 'learing e-mail as ham' do
			# POST /learnham HTTP/1.0
			# Content-Length: 414

			when_i_make_post_request_to '/learnham', with_body: spam.to_s

			then_response_status_should_be 200
			then_response_should_contain_json_with an_object_eq_to('success' => true)

			# should be spam by bayes
			when_i_make_post_request_to '/check', with_body: spam.to_s, with_client: normal_client

			then_response_should_contain_json_with a_collection_including(
				'default' => a_collection_including(
					'BAYES_HAM' => a_collection_including('score' => an_instance_of(Float)),
				)
			)
			then_response_should_contain_json_without a_collection_including(
				'default' => a_collection_including(
					'BAYES_SPAM' => a_collection_including('score' => an_instance_of(Float)),
				)
			)
		end

		scenario 'adding e-mail to fuzzy hash store with given flag' do
			# POST /fuzzyadd HTTP/1.0
			# Content-Length: 414
			# Flag: 1
			pending 'may be used in future'
			pass
		end
	end
end


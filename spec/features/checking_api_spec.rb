require_relative '../spec_helper'

feature 'e-mail checking API', httpspamscorer: :server, with: :spam_examples do
	def then_response_status_should_be(status)
		expect(@resp).to have_attributes(status: status)
	end

	def then_response_should_contain_json
		expect(@resp.get_header('Content-Type')).to eq('application/json')
		@json_resp = JSON.parse(@resp.body)
	end

	def then_json_response_should_contain_error_message
		expect(@json_resp).to include 'error' => an_instance_of(String)
	end

	def then_json_response_should_contain_error_message_including(msg)
		expect(@json_resp).to include 'error' => a_string_including(msg)
	end

	def then_json_response_should_be(matcher)
		expect(@json_resp).to matcher
	end

	context 'passing parsed e-mail for scoring', rspamd: :server do
		def when_i_post_message_headers_and_body_plain_to_check_uri
			@resp = http.post(
				path: '/check',
				body: JSON.dump(
					{
						'message-headers' => ham_headers,
						'body-plain' => ham_text_part
					}
				)
			)
		end

		scenario 'checking plain part' do
			when_i_post_message_headers_and_body_plain_to_check_uri

			then_response_status_should_be 200
			then_response_should_contain_json
			then_json_response_should_be a_collection_including(
				'is_spam' => false,
				'is_skipped' => false,
				'score' => an_instance_of(Float),
				'required_score' => an_instance_of(Float),
				'action' => an_instance_of(String),
				'R_SPF_ALLOW' => a_collection_including('score' => an_instance_of(Float))
			)
		end

		def when_i_post_message_headers_with_body_plain_and_body_html_to_check_uri
			@resp = http.post(
				path: '/check',
				body: JSON.dump(
					{
						'message-headers' => ham_headers,
						'body-plain' => ham_text_part,
						'body-html' => ham_html_part
					}
				)
			)
		end

		scenario 'checking plain and html parts' do
			when_i_post_message_headers_with_body_plain_and_body_html_to_check_uri

			then_response_status_should_be 200
			then_response_should_contain_json
			then_json_response_should_be a_collection_including(
				'is_spam' => false,
				'is_skipped' => false,
				'score' => an_instance_of(Float),
				'required_score' => an_instance_of(Float),
				'action' => an_instance_of(String),
				'R_SPF_ALLOW' => a_collection_including('score' => an_instance_of(Float)), # headers checked
				'R_PARTS_DIFFER' => a_collection_including('score' => an_instance_of(Float)) # Text and HTML parts differ
			)
		end

		context 'passing additional context information' do
			def when_i_post_message_headers_and_body_plain_to_check_uri_with_additional_values(values)
				@resp = http.post(
					path: '/check',
					body: JSON.dump(
						{
							'message-headers' => spam_headers,
							'body-plain' => spam_text_part
						}.merge(values)
					)
				)
			end

			scenario 'passing context information to spam scoring with rspamd headers' do
				when_i_post_message_headers_and_body_plain_to_check_uri_with_additional_values(
					'helo' => 'fdsa', # verify SMTP hello message - HFILTER_HELO_NOT_FQDN
					'ip' => '192.168.0.1', # verify SMTP hello message - HFILTER_HELO_NOT_FQDN
					'from' => 'bfalsdh@compuware.com', # verify sender with email - FORGED_SENDER
					'rcpt' => 'dfas@whatclinic.com', # verify recipient with email - FORGED_RECIPIENTS
					'user' => 'jpastuszek', # logging
					'deliver-to' => 'dfas'
				)

				then_response_status_should_be 200
				then_response_should_contain_json
				then_json_response_should_be a_collection_including(
					'is_spam' => false,
					'is_skipped' => false,
					'score' => an_instance_of(Float),
					'required_score' => an_instance_of(Float),
					'action' => an_instance_of(String),
					'HFILTER_HELO_NOT_FQDN' => a_collection_including('score' => an_instance_of(Float)), # helo
					'FORGED_SENDER' => a_collection_including('score' => an_instance_of(Float)), # from
					'FORGED_RECIPIENTS' => a_collection_including('score' => an_instance_of(Float)) # rcpt
				)
			end

			scenario 'passing context information to spam scoring with received' do
				when_i_post_message_headers_and_body_plain_to_check_uri_with_additional_values(
					'received' => 'from foobaz ([86.43.88.8]) by mx.google.com with ESMTPSA id t9sm3066150wjf.41.2014.09.25.08.36.42 for <test@sandboxaa5c302b487f44fe90ee9479494fbb1c.mailgun.org> (version=TLSv1 cipher=ECDHE-RSA-RC4-SHA bits=128/128); Thu, 25 Sep 2014 08:36:42 -0700 (PDT)'
				)

				then_response_status_should_be 200
				then_response_should_contain_json
				then_json_response_should_be a_collection_including(
					'is_spam' => false,
					'is_skipped' => false,
					'score' => an_instance_of(Float),
					'required_score' => an_instance_of(Float),
					'action' => an_instance_of(String),
					'HFILTER_HELO_NOT_FQDN' => a_collection_including('score' => an_instance_of(Float)), # helo (foobaz)
					'FORGED_RECIPIENTS' => a_collection_including('score' => an_instance_of(Float)) # for <...
				)
			end
		end
	end

	context 'error handling' do
		def when_i_call_api_with_bad_verb
			@resp = http.get(
				path: '/check',
				body: JSON.dump(
					{
						'message-headers' => spam_headers,
						'body-plain' => spam_text_part
					}
				)
			)
		end

		scenario 'bad verb' do
			when_i_call_api_with_bad_verb

			then_response_status_should_be 404
			then_response_should_contain_json
			then_json_response_should_contain_error_message
		end

		def when_i_call_api_with_bad_uri
			@resp = http.post(
				path: '/checkX',
				body: JSON.dump(
					{
						'message-headers' => spam_headers,
						'body-plain' => spam_text_part
					}
				)
			)
		end

		scenario 'bad URI' do
			when_i_call_api_with_bad_uri

			then_response_status_should_be 404
			then_response_should_contain_json
			then_json_response_should_contain_error_message
		end

		def when_i_call_api_with_missing_message_headers
			@resp = http.post(
				path: '/check',
				body: JSON.dump(
					{
						'body-plain' => spam_text_part
					}
				)
			)
		end

		scenario 'missing message headers' do
			when_i_call_api_with_missing_message_headers

			then_response_status_should_be 400
			then_response_should_contain_json
			then_json_response_should_contain_error_message_including 'no headers provided'
		end
	end
end

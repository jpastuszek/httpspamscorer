require_relative '../spec_helper'

feature 'e-mail checking API', httpspamscorer: :server, with: :spam_examples do
	context 'passing parsed e-mail for scoring', rspamd: :server do
		scenario 'checking plain part' do
			when_i_make_JSON_post_request_to '/check', with_json: {
				'message-headers' => ham_headers,
				'body-plain' => ham_text_part
			}

			then_response_status_should_be 200
			then_response_should_contain_json_with a_collection_including(
				'is_spam' => false,
				'is_skipped' => false,
				'score' => an_instance_of(Float),
				'required_score' => an_instance_of(Float),
				'action' => an_instance_of(String),
				'R_SPF_ALLOW' => a_collection_including('score' => an_instance_of(Float))
			)
		end

		scenario 'checking plain and html parts' do
			when_i_make_JSON_post_request_to '/check', with_json: {
				'message-headers' => ham_headers,
				'body-plain' => ham_text_part,
				'body-html' => ham_html_part
			}

			then_response_status_should_be 200
			then_response_should_contain_json_with a_collection_including(
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
			scenario 'passing context information to spam scoring with rspamd headers' do
				when_i_make_JSON_post_request_to '/check', with_json: {
					'message-headers' => ham_headers,
					'body-plain' => ham_text_part,
					'helo' => 'fdsa', # verify SMTP hello message - HFILTER_HELO_NOT_FQDN
					'ip' => '192.168.0.1', # verify SMTP hello message - HFILTER_HELO_NOT_FQDN
					'from' => 'bfalsdh@compuware.com', # verify sender with email - FORGED_SENDER
					'rcpt' => 'dfas@whatclinic.com', # verify recipient with email - FORGED_RECIPIENTS
					'user' => 'jpastuszek', # logging
					'deliver-to' => 'dfas'
				}

				then_response_status_should_be 200
				then_response_should_contain_json_with a_collection_including(
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
				when_i_make_JSON_post_request_to '/check', with_json: {
					'message-headers' => ham_headers,
					'body-plain' => ham_text_part,
					'received' => 'from foobaz ([86.43.88.8]) by mx.google.com with ESMTPSA id t9sm3066150wjf.41.2014.09.25.08.36.42 for <test@sandboxaa5c302b487f44fe90ee9479494fbb1c.mailgun.org> (version=TLSv1 cipher=ECDHE-RSA-RC4-SHA bits=128/128); Thu, 25 Sep 2014 08:36:42 -0700 (PDT)'
				}

				then_response_status_should_be 200
				then_response_should_contain_json_with a_collection_including(
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
		scenario 'bad verb' do
			when_i_make_get_request_to '/check'

			then_response_status_should_be 404
			then_response_should_contain_json_with_error_message
		end

		scenario 'missing message headers' do
			when_i_make_JSON_post_request_to '/check', with_json: {
				'body-plain' => ham_text_part
			}

			then_response_status_should_be 400
			then_response_should_contain_json_with_error_message 'no headers provided'
		end

		scenario 'missing body' do
			when_i_make_JSON_post_request_to '/check', with_json: {
				'message-headers' => ham_headers
			}

			then_response_status_should_be 400
			then_response_should_contain_json_with_error_message 'no text or html body provided'
		end

		scenario 'bad message headers' do
			when_i_make_JSON_post_request_to '/check', with_json: {
				'message-headers' => ['foobar'],
				'body-plain' => ham_text_part
			}

			then_response_status_should_be 400
			then_response_should_contain_json_with_error_message 'no header name or value'
		end
	end
end

feature 'server logging of e-mail checking', httpspamscorer: :server, with: :spam_examples do
	scenario 'metadata logged for checked e-mail' do
		given_empty_log_file

		when_i_make_JSON_post_request_to '/check', with_json: {
			'message-headers' => ham_headers,
			'body-plain' => ham_text_part
		}

		then_log_file_should_contain_line including 'check result'
		then_matched_line_should_contain_meta including(
			'message-id' => ham.message_id,
			'from' => ham.from,
			'to' => ham.to,
			'is_spam' => false,
			'action' => an_instance_of(String),
			'ip' => a_string_matching(/(:|.)/),
			'score' => an_instance_of(Float),
			'required_score' => an_instance_of(Float),
			'symbols' => a_collection_including('R_SPF_ALLOW')
		)
	end
end

feature 'checking API statistics', httpspamscorer: :server do
	scenario 'retrieving check statistics' do
		when_i_make_get_request_to '/stats'

		then_response_status_should_be 200
		then_response_should_contain_plain_text_with(
			a_string_including('total_emails_checked: ')
			.and including('total_spam: ')
			.and including('total_ham: ')
		)
	end
end

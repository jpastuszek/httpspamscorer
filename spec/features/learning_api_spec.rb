require_relative '../spec_helper'

feature 'e-mail learning API', httpspamscorer: :server, with: :spam_examples do
	context 'passing parsed e-mail for learning', rspamd: :server do
		scenario 'learning spam' do
			# not learned
			when_i_make_post_request_to '/check', with_json: {
				'message-headers' => spam_headers,
				'body-plain' => spam_text_part
			}

			then_response_should_contain_json
			then_json_response_should_not_be a_collection_including(
				'BAYES_SPAM'
			)

			# learn
			when_i_make_post_request_to '/learn/spam', with_json: {
				'message-headers' => spam_headers,
				'body-plain' => spam_text_part
			}

			then_response_status_should_be 200
			then_response_should_contain_json
			then_json_response_should_be a_collection_including(
				'success' => true
			)

			# learned
			when_i_make_post_request_to '/check', with_json: {
				'message-headers' => spam_headers,
				'body-plain' => spam_text_part
			}

			then_response_should_contain_json
			then_json_response_should_be a_collection_including(
				'BAYES_SPAM' => a_collection_including('score' => an_instance_of(Float))
			)
		end

		scenario 'learning ham' do
			# not learned
			when_i_make_post_request_to '/check', with_json: {
				'message-headers' => spam_headers,
				'body-plain' => spam_text_part
			}

			then_response_should_contain_json
			then_json_response_should_not_be a_collection_including(
				'BAYES_HAM'
			)

			# learn
			when_i_make_post_request_to '/learn/ham', with_json: {
				'message-headers' => spam_headers,
				'body-plain' => spam_text_part
			}

			then_response_status_should_be 200
			then_response_should_contain_json
			then_json_response_should_be a_collection_including(
				'success' => true
			)

			# learned
			when_i_make_post_request_to '/check', with_json: {
				'message-headers' => spam_headers,
				'body-plain' => spam_text_part
			}

			then_response_should_contain_json
			then_json_response_should_be a_collection_including(
				'BAYES_HAM' => a_collection_including('score' => an_instance_of(Float))
			)
		end
	end
end

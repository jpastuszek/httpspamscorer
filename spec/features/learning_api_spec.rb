require_relative '../spec_helper'

feature 'e-mail learning API', httpspamscorer: :server, with: :spam_examples do
	context 'passing parsed e-mail for learning', rspamd: :server do
		def given_spam_is_not_scored_with_symbol(symbol)
			when_i_make_JSON_post_request_to '/check', with_json: {
				'message-headers' => spam_headers,
				'body-plain' => spam_text_part
			}
			then_response_should_contain_json_without a_collection_including(symbol)
		end

		def then_spam_is_scored_with_symbol(symbol)
			when_i_make_JSON_post_request_to '/check', with_json: {
				'message-headers' => spam_headers,
				'body-plain' => spam_text_part
			}
			then_response_should_contain_json_with a_collection_including(symbol)
		end

		scenario 'learning spam' do
			given_spam_is_not_scored_with_symbol 'BAYES_SPAM'

			when_i_make_JSON_post_request_to '/learn/spam', with_json: {
				'message-headers' => spam_headers,
				'body-plain' => spam_text_part
			}

			then_response_status_should_be 200
			then_response_should_contain_json_with a_collection_including(
				'success' => true
			)

			then_spam_is_scored_with_symbol 'BAYES_SPAM'
		end

		scenario 'learning ham' do
			given_spam_is_not_scored_with_symbol 'BAYES_HAM'

			# learn
			when_i_make_JSON_post_request_to '/learn/ham', with_json: {
				'message-headers' => spam_headers,
				'body-plain' => spam_text_part
			}

			then_response_status_should_be 200
			then_response_should_contain_json_with a_collection_including(
				'success' => true
			)

			then_spam_is_scored_with_symbol 'BAYES_HAM'
		end
	end
end

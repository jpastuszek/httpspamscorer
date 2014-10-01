require_relative '../spec_helper'

feature 'API error handling with JSON responses', httpspamscorer: :server do
	scenario 'bad URI' do
		when_i_make_post_request_to '/foobar'

		then_response_status_should_be 404
		then_response_should_contain_json
		then_json_response_should_contain_error_message
	end
end

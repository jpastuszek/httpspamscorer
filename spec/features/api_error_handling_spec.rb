require_relative '../spec_helper'

feature 'API error handling with JSON responses', httpspamscorer: :server do
	scenario 'bad URI' do
		when_i_make_get_request_to '/foobar'

		then_response_status_should_be 404
		then_response_should_contain_json_with_error_message including('was not handled by the server')
	end

	scenario 'no JSON post body' do
		when_i_make_JSON_post_request_to '/foobar'

		then_response_status_should_be 400
		then_response_should_contain_json_with_error_message including('JSON text must at least contain two octets')
	end
end

require_relative '../spec_helper'

feature 'stat API providing usage statistics', httpspamscorer: :server do
	scenario 'retrieving generic statistics' do
		when_i_make_get_request_to '/stats'

		then_response_status_should_be 200
		then_response_should_contain_plain_text_with a_string_including('workers: ')
	end
end

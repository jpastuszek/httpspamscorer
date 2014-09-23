require_relative '../spec_helper'

feature 'passing parsed JSON e-mail to rspamd', rspamd: :server, httpspamscorer: :server do
	let :spam do
		File.read('spec/support/spam1.eml')
	end

	scenario 'checking spam score' do
		resp = http.post path: '/check', body: JSON.dump(
			{
				'body-plain' => spam
			}
		)

		expect(JSON.parse(resp.body)).to a_collection_including(
			'default' => a_collection_including(
				'is_spam' => false,
				'is_skipped' => false,
				'score' => an_instance_of(Float),
				'required_score' => an_instance_of(Float),
				'action' => 'no action',
				#'HFILTER_HELO_NOT_FQDN' => a_collection_including('score' => an_instance_of(Float)),
				#'FORGED_SENDER' => a_collection_including('score' => an_instance_of(Float)),
				#'FORGED_RECIPIENTS' => a_collection_including('score' => an_instance_of(Float))
			)
		)
	end
end

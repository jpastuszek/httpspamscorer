require_relative '../spec_helper'

feature 'passing parsed JSON e-mail to rspamd', rspamd: :server, httpspamscorer: :server, with: :spam_examples do
	scenario 'checking spam score' do
		resp = http.post(
			path: '/check',
			body: JSON.dump(
				{
					'message-headers' => headers,
					'body-plain' => spam.text_part.body.to_s.encode('UTF-8', {:invalid => :replace, :undef => :replace, :replace => '?'})
				}
			)
		)

		expect(resp.status).to eq(200)

		body = resp.body
		puts body

		expect(JSON.parse(body)).to a_collection_including(
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

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
		#puts body

		expect(JSON.parse(body)).to a_collection_including(
			'default' => a_collection_including(
				'is_spam' => false,
				'is_skipped' => false,
				'score' => an_instance_of(Float),
				'required_score' => an_instance_of(Float),
				'action' => 'no action'
			)
		)
	end

	scenario 'passing context information to spam scoring with rspamd headers' do
		resp = http.post(
			path: '/check',
			body: JSON.dump(
				{
					'message-headers' => headers,
					'body-plain' => spam.text_part.body.to_s.encode('UTF-8', {:invalid => :replace, :undef => :replace, :replace => '?'}),
					'helo' => 'fdsa', # verify SMTP hello message - HFILTER_HELO_NOT_FQDN
					'ip' => '192.168.0.1', # verify SMTP hello message - HFILTER_HELO_NOT_FQDN
					'from' => 'bfalsdh@compuware.com', # verify sender with email - FORGED_SENDER
					'rcpt' => 'dfas@whatclinic.com', # verify recipient with email - FORGED_RECIPIENTS
					'user' => 'jpastuszek', # logging
					'deliver-to' => 'dfas'
				}
			)
		)

		expect(resp.status).to eq(200)

		body = resp.body

		expect(JSON.parse(body)).to a_collection_including(
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

	scenario 'passing context information to spam scoring with received' do
		resp = http.post(
			path: '/check',
			body: JSON.dump(
				{
					'message-headers' => headers,
					'body-plain' => spam.text_part.body.to_s.encode('UTF-8', {:invalid => :replace, :undef => :replace, :replace => '?'}),
					'received' => 'from foobaz ([86.43.88.8]) by mx.google.com with ESMTPSA id t9sm3066150wjf.41.2014.09.25.08.36.42 for <test@sandboxaa5c302b487f44fe90ee9479494fbb1c.mailgun.org> (version=TLSv1 cipher=ECDHE-RSA-RC4-SHA bits=128/128); Thu, 25 Sep 2014 08:36:42 -0700 (PDT)'
				}
			)
		)

		expect(resp.status).to eq(200)

		body = resp.body

		#pp JSON.parse(body)

		expect(JSON.parse(body)).to a_collection_including(
			'default' => a_collection_including(
				'is_spam' => false,
				'is_skipped' => false,
				'score' => an_instance_of(Float),
				'required_score' => an_instance_of(Float),
				'action' => an_instance_of(String),
				'HFILTER_HELO_NOT_FQDN' => a_collection_including('score' => an_instance_of(Float)),
				#'FORGED_SENDER' => a_collection_including('score' => an_instance_of(Float)),
				'FORGED_RECIPIENTS' => a_collection_including('score' => an_instance_of(Float))
			)
		)
	end

	scenario 'passing context information to spam scoring with received headers' do
		resp = http.post(
			path: '/check',
			body: JSON.dump(
				{
					'message-headers' => gmail_headers,
					'body-plain' => spam.text_part.body.to_s.encode('UTF-8', {:invalid => :replace, :undef => :replace, :replace => '?'}),
				}
			)
		)

		expect(resp.status).to eq(200)

		body = resp.body

		#pp JSON.parse(body)

		expect(JSON.parse(body)).to a_collection_including(
			'default' => a_collection_including(
				'is_spam' => false,
				'is_skipped' => false,
				'score' => an_instance_of(Float),
				'required_score' => an_instance_of(Float),
				'action' => an_instance_of(String),
				'R_SPF_ALLOW' => a_collection_including('score' => an_instance_of(Float)),
				'RWL_MAILSPIKE_GOOD' => a_collection_including('score' => an_instance_of(Float)),
				#'FORGED_SENDER' => a_collection_including('score' => an_instance_of(Float)),
				'FORGED_RECIPIENTS' => a_collection_including('score' => an_instance_of(Float))
			)
		)
	end
end

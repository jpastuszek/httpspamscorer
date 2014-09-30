require_relative '../spec_helper'

feature 'e-mail checking API', rspamd: :server, httpspamscorer: :server, with: :spam_examples do
	context 'passing parsed e-mail for scoring' do
		scenario 'checking plain part' do
			resp = http.post(
				path: '/check',
				body: JSON.dump(
					{
						'message-headers' => ham_headers,
						'body-plain' => ham_text_part
					}
				)
			)

			expect(resp.status).to eq(200)

			body = resp.body

			expect(JSON.parse(body)).to a_collection_including(
				'is_spam' => false,
				'is_skipped' => false,
				'score' => an_instance_of(Float),
				'required_score' => an_instance_of(Float),
				'action' => an_instance_of(String),
				'R_SPF_ALLOW' => a_collection_including('score' => an_instance_of(Float))
			)
		end

		scenario 'checking plain and html parts' do
			resp = http.post(
				path: '/check',
				body: JSON.dump(
					{
						'message-headers' => ham_headers,
						'body-plain' => ham_text_part,
						'body-html' => ham_html_part
					}
				)
			)

			expect(resp.status).to eq(200)

			body = resp.body

			expect(JSON.parse(body)).to a_collection_including(
				'is_spam' => false,
				'is_skipped' => false,
				'score' => an_instance_of(Float),
				'required_score' => an_instance_of(Float),
				'action' => an_instance_of(String),
				'R_SPF_ALLOW' => a_collection_including('score' => an_instance_of(Float)), # headers checked
				'R_PARTS_DIFFER' => a_collection_including('score' => an_instance_of(Float)) # Text and HTML parts differ
			)
		end
	end

	context 'passing additional context information' do
		scenario 'passing context information to spam scoring with rspamd headers' do
			resp = http.post(
				path: '/check',
				body: JSON.dump(
					{
						'message-headers' => spam_headers,
						'body-plain' => spam_text_part,
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
			resp = http.post(
				path: '/check',
				body: JSON.dump(
					{
						'message-headers' => spam_headers,
						'body-plain' => spam_text_part,
						'received' => 'from foobaz ([86.43.88.8]) by mx.google.com with ESMTPSA id t9sm3066150wjf.41.2014.09.25.08.36.42 for <test@sandboxaa5c302b487f44fe90ee9479494fbb1c.mailgun.org> (version=TLSv1 cipher=ECDHE-RSA-RC4-SHA bits=128/128); Thu, 25 Sep 2014 08:36:42 -0700 (PDT)'
					}
				)
			)

			expect(resp.status).to eq(200)

			body = resp.body

			expect(JSON.parse(body)).to a_collection_including(
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

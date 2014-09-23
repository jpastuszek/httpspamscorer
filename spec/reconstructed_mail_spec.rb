require_relative 'spec_helper'

require_relative '../lib/httpspamscorer/reconstructed_mail'

describe ReconstructedMail do
	let :spam do
		Mail.read('spec/support/spam1.eml')
	end

	describe '#from_hash' do
		it 'should create e-mail message object from hash of values' do
			headers = spam.header.to_a.map{|h| [h.name, h.value]}

			#puts spam.attachments

			msg = described_class.from_hash(
				'body-plain' => spam.text_part.body.to_s,
				'body-html' => spam.html_part.body.to_s,
				'message-headers' => headers
				#'attachements' =>
			)

			#p msg
			#puts msg.to_s

			expect(msg.text_part.body.to_s).to eq(spam.text_part.body.to_s)
			expect(msg.html_part.body.to_s).to eq(spam.html_part.body.to_s)

			msg.header.to_a.map{|h| [h.name, h.value]}
			.reject{|name, _| name == 'Content-Type'} # boundry will differ
			.each do |h|
				expect(headers).to include(h)
			end
		end
	end
end

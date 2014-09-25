require_relative 'spec_helper'

require_relative '../lib/httpspamscorer/reconstructed_mail'

describe ReconstructedMail do
	let :spam do
		Mail.read('spec/support/spam1.eml')
	end

	let :spam_attachment do
		spam.dup.tap{|spam| spam.add_file('spec/support/image.png')}
	end

	let :attachment_body do
		File.open('spec/support/image.png', 'rb'){|io| return io.read}
	end

	describe '#from_hash' do
		it 'should create e-mail message object from hash of values' do
			headers = spam_attachment.header.to_a.map{|h| [h.name, h.value]}

			msg = described_class.from_hash(
				'body-plain' => spam.text_part.body.to_s,
				'body-html' => spam.html_part.body.to_s,
				'message-headers' => headers,
				'attachments' => spam_attachment.attachments.map do |att|
					{
						'filename' => att.filename,
						'body' => att.body.to_s
					}
				end
			)

			expect(
				msg.header.to_a
			).to match(
				headers.map do |name, value|
					if name == 'Content-Type'
						an_object_having_attributes(
							:name => name,
							:value => a_string_starting_with(value.split(';', 2).first) #  boundry will differ
						)
					else
						an_object_having_attributes(
							:name => name,
							:value => value
						)
					end
				end
			)

			expect(msg.text_part.body.to_s).to eq(spam.text_part.body.to_s)
			expect(msg.html_part.body.to_s).to eq(spam.html_part.body.to_s)

			expect(msg.attachments).to contain_exactly(
				an_object_having_attributes(
					:filename => 'image.png',
					:body => attachment_body
				)
			)
		end
	end
end

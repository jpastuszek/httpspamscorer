require_relative 'spec_helper'

require_relative '../lib/httpspamscorer/reconstructed_mail'

describe ReconstructedMail, with: :spam_examples do
	describe '#from_hash' do
		context 'when used to crate e-mail message from given map of values' do
			describe 'created e-mail message' do
				subject do
					described_class.from_hash(
						'message-headers' => spam_headers,
						'body-plain' => spam_text_part,
						'body-html' => spam_html_part,
						'attachments' => spam_with_attachment.attachments.map do |att|
							{
								'filename' => att.filename,
								'body' => att.body.to_s
							}
						end
					)
				end

				its('header.to_a') {
					should match(
						spam_headers.map do |name, value|
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
				}

				its('text_part.body.to_s') { should eq(spam_text_part) }
				its('html_part.body.to_s') { should eq(spam_html_part) }

				its('attachments') {
					should contain_exactly(
						an_object_having_attributes(
							:filename => 'image.png',
							:body => attachment
						)
					)
				}
			end
		end

		it 'should raise error if no headers are provided' do
			expect {
				described_class.from_hash(
					#'message-headers' => spam_headers,
					'body-plain' => spam_text_part,
					'body-html' => spam_html_part,
					'attachments' => spam_with_attachment.attachments.map do |att|
						{
						'filename' => att.filename,
						'body' => att.body.to_s
						}
					end
				)
			}.to raise_error ReconstructedMail::ReconstructionError, 'no headers provided'
		end

		it 'should raise error if headers are not array' do
			expect {
				described_class.from_hash(
					'message-headers' => '[fdsalhfds]',
					'body-plain' => spam_text_part,
					'body-html' => spam_html_part,
					'attachments' => spam_with_attachment.attachments.map do |att|
						{
							'filename' => att.filename,
							'body' => att.body.to_s
						}
					end
				)
			}.to raise_error ReconstructedMail::ReconstructionError, 'headers not array'
		end

		it 'should raise error if headers are not array of 2 element array' do
			expect {
				described_class.from_hash(
					'message-headers' => ['hello', 'world'],
					'body-plain' => spam_text_part,
					'body-html' => spam_html_part,
					'attachments' => spam_with_attachment.attachments.map do |att|
						{
							'filename' => att.filename,
							'body' => att.body.to_s
						}
					end
				)
			}.to raise_error ReconstructedMail::ReconstructionError, 'no header name or value'
		end

		it 'should raise error if no text or html body is provided' do
			expect {
				described_class.from_hash(
					'message-headers' => spam_headers,
					#'body-plain' => spam_text_part,
					#'body-html' => spam_html_part,
					'attachments' => spam_with_attachment.attachments.map do |att|
						{
						'filename' => att.filename,
						'body' => att.body.to_s
						}
					end
				)
			}.to raise_error ReconstructedMail::ReconstructionError, 'no text or html body provided'
		end

		it 'should accept missing body-plain provided body-html' do
			expect {
				described_class.from_hash(
					'message-headers' => spam_headers,
					#'body-plain' => spam_text_part,
					'body-html' => spam_html_part,
					'attachments' => spam_with_attachment.attachments.map do |att|
						{
							'filename' => att.filename,
							'body' => att.body.to_s
						}
					end
				)
			}.to_not raise_error
		end

		it 'should accept missing body-html provided body-plain' do
			expect {
				described_class.from_hash(
					'message-headers' => spam_headers,
					'body-plain' => spam_text_part,
					#'body-html' => spam_html_part,
					'attachments' => spam_with_attachment.attachments.map do |att|
						{
							'filename' => att.filename,
							'body' => att.body.to_s
						}
					end
				)
			}.to_not raise_error
		end

		it 'should accept no attachments' do
			expect {
				described_class.from_hash(
					'message-headers' => spam_headers,
					'body-plain' => spam_text_part,
					'body-html' => spam_html_part,
					#'attachments' => spam_with_attachment.attachments.map do |att|
					#	{
					#		'filename' => att.filename,
					#		'body' => att.body.to_s
					#	}
					#end
				)
			}.to_not raise_error
		end
	end
end

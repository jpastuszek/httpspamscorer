require 'mail'

class ReconstructedMail < Mail::Message
	def initialize(_headers, _text_body, _html_body, _attachments)
		super()

		_headers or raise(ArgumentError, 'no headers provided')
		not _text_body and not _html_body and raise(ArgumentError, 'no text or html body provided')

		_headers.each do |name, value|
			self.header[name] = value # Note that setting header twice appends it
		end

		self.text_part = Mail::Part.new do
			body _text_body
		end if _text_body

		self.html_part = Mail::Part.new do
			content_type 'text/html; charset=UTF-8'
			body _html_body
		end if _html_body

		_attachments.each do |att|
			self.attachments[att['filename']] = att['body']
		end if _attachments
	end

	def self.from_hash(msg)
		self.new(
			msg['message-headers'],
			msg['body-plain'],
			msg['body-html'],
			msg['attachments']
		)
	end
end

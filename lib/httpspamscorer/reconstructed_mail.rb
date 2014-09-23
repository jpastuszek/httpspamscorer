require 'mail'

class ReconstructedMail < Mail::Message
	def initialize(_headers, _text_body, _html_body, _attachements)
		super()

		self.headers Hash[_headers]

		self.text_part = Mail::Part.new do
			body _text_body
		end

		self.html_part = Mail::Part.new do
			content_type 'text/html; charset=UTF-8'
			body _html_body
		end
	end

	def self.from_hash(msg)
		self.new(
			msg['message-headers'],
			msg['body-plain'],
			msg['body-html'],
			msg['attachements']
		)
	end
end

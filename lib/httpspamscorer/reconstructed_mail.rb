require 'mail'

class ReconstructedMail < Mail::Message
	def initialize(_recipient, _sender, _from, _subject, _body)
		super() do
			to      _recipient
			from    _from
			subject _subject
			body    _body
		end
	end

	def from_hash(msg)
		p msg
		self.new(
			msg['recipient'],
			msg['sender'],
			msg['from'],
			msg['subject'],
			msg['body-plain']
		)
	end
end

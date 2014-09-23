require_relative 'spec_helper'

require_relative '../lib/httpspamscorer/reconstructed_mail'

describe ReconstructedMail do
	describe '#from_hash' do
		it 'should create e-mail message object from hash of values' do
			msg = described_class.from_hash(
				'from' => 'foo@baz.com'
			)

			p msg
			puts msg.to_s
		end
	end
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'httpspamscorer'
require 'mail'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

require 'cucumber-spawn-process'

require 'rspec/core/shared_context'
require 'excon'
require 'json'

module RSpamdLegacy
	extend RSpec::Core::SharedContext

	let :rspamd do
		@rspamd
	end

	before (:all) do
		@rspamd = background_process('spec/support/rspamd').with do |process|
			process.argument '--no-fork'
			process.argument '--insecure'
			process.argument '--debug'
			process.argument '--pid', 'rspamd.pid'
			process.argument '--config', '<project directory>/spec/support/rspamd-legacy.conf'

			process.ready_when_log_includes 'main: calling sigsuspend'
			#process.logging_enabled
		end
		.start
		.wait_ready
	end
end

module RSpamd
	extend RSpec::Core::SharedContext

	let :rspamd do
		@rspamd
	end

	before (:all) do
		@rspamd = background_process('spec/support/rspamd').with do |process|
			process.argument '--no-fork'
			process.argument '--insecure'
			process.argument '--debug'
			process.argument '--pid', 'rspamd.pid'
			process.argument '--config', '<project directory>/spec/support/rspamd.conf.d/rspamd.conf'

			process.ready_when_log_includes 'main: calling sigsuspend'

			# get rid of learned stats
			process.refresh_command 'test -f bayes.spam && rm -f bayes.spam'
			#process.logging_enabled
		end
		.start
		.wait_ready
	end

	before (:each) do
		rspamd.refresh
		rspamd.restart.wait_ready
	end
end

module HTTPSpamScorer
	extend RSpec::Core::SharedContext

	let :httpspamscorer do
		@httpspamscorer
	end

	let :http do
		Excon.new('http://localhost:4000', read_timeout: 4)
	end

	before (:all) do
		@httpspamscorer = background_process('bin/httpspamscorer').with do |process|
			process.argument '--foreground'
			process.argument '--debug'

			process.ready_when_log_includes 'worker=0 ready'
		end
		.start
		.wait_ready
	end
end

module SpamExamples
	extend RSpec::Core::SharedContext

	let :spam do
		Mail.read('spec/support/spam1.eml')
	end

	let :spam_attachment do
		spam.dup.tap{|spam| spam.add_file('spec/support/image.png')}
	end

	let :attachment_body do
		File.open('spec/support/image.png', 'rb'){|io| return io.read}
	end

	let :headers do
		spam_attachment.header.to_a.map{|h| [h.name, h.value]}
	end
end

RSpec.configure do |config|
	config.include SpawnProcessHelpers
	config.include RSpamdLegacy, rspamd: :legacy
	config.include RSpamd, rspamd: :server
	config.include HTTPSpamScorer, httpspamscorer: :server
	config.include SpamExamples, with: :spam_examples

	config.alias_example_group_to :feature
	config.alias_example_to :scenario

	config.add_formatter FailedInstanceReporter
end

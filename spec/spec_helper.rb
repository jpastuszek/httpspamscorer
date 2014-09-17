$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'httpspamscorer'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

require 'cucumber-spawn-process'

require 'rspec/core/shared_context'

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
			process.logging_enabled
		end
		.start
		.wait_ready
	end
end

RSpec.configure do |config|
	config.include SpawnProcessHelpers
	config.include RSpamdLegacy, rspamd: :legacy
	config.include RSpamd, rspamd: :server

	config.alias_example_group_to :feature
	config.alias_example_to :scenario

	config.add_formatter FailedInstanceReporter
end

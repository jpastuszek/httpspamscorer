$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'rspec/its'
require 'httpspamscorer'
require 'mail'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

require 'rspec-background-process'

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

	before :all do
		@httpspamscorer = background_process('bin/httpspamscorer').with do |process|
			process.argument '--foreground'
			process.argument '--debug'

			process.ready_when_log_includes 'worker=0 ready'
		end
		.start
		.wait_ready
	end

	after :all do
		puts "Log file: #{@httpspamscorer.log_file}"
	end

	def given_empty_log_file
		@httpspamscorer.log_file.truncate(0)
	end

	def then_log_file_should(matcher)
		@log_data = @httpspamscorer.log_file.read
		expect(@log_data).to matcher
	end

	def then_log_file_should_contain_line(matcher)
		@log_data = @httpspamscorer.log_file.read
		expect(@log_data).to matcher
		@matched_line = @log_data.each_line.select{|line| matcher.matches? line}.last
	end

	def then_matched_line_should_contain_meta(matcher)
		expect(JSON.parse(@matched_line.match(/\[meta ({.*})\]/).captures.first)).to matcher
	end
end

module SpamExamples
	extend RSpec::Core::SharedContext

	let :spam do
		Mail.read('spec/support/spam.eml')
	end

	let :spam_headers do
		spam.header.to_a.map{|h| [h.name, h.value]}
	end

	let :spam_text_part do
		spam.text_part.body.to_s
	end

	let :spam_html_part do
		spam.html_part.body.to_s
	end

	let :spam_with_attachment do
		spam.dup.tap{|spam| spam.add_file('spec/support/image.png')}
	end

	let :attachment do
		File.open('spec/support/image.png', 'rb'){|io| return io.read}
	end

	let :ham do
		Mail.read('spec/support/ham.eml')
	end

	let :ham_headers do
		ham.header.to_a.map{|header| [header.name, header.value]}
	end

	let :ham_text_part do
		ham.text_part.body.to_s
	end

	let :ham_html_part do
		ham.html_part.body.to_s
	end
end

def pj(json)
	puts JSON.pretty_generate(JSON.parse(json))
end

module HTTPHelpers
	def when_i_make_get_request_to(uri)
		@resp = http.get path: uri
	end

	def when_i_make_post_request_to(uri, options = {})
		req = {}
		req[:path] = uri
		req[:body] = JSON.dump(options[:with_json]) if options.key? :with_json

		@resp = http.post req
	end

	def then_response_status_should_be(status)
		expect(@resp).to have_attributes(status: status)
	end

	def then_response_should_contain_json
		expect(@resp.get_header('Content-Type')).to eq('application/json')
		@json_resp = JSON.parse(@resp.body)
	end

	def then_json_response_should_contain_error_message
		expect(@json_resp).to include 'error' => an_instance_of(String)
	end

	def then_json_response_should_contain_error_message_including(msg)
		expect(@json_resp).to include 'error' => a_string_including(msg)
	end

	def then_json_response_should_be(matcher)
		expect(@json_resp).to matcher
	end
end

RSpec.configure do |config|
	config.include HTTPHelpers

	config.include RSpamdLegacy, rspamd: :legacy
	config.include BackgroundProcessHelpers, rspamd: :legacy

	config.include RSpamd, rspamd: :server
	config.include BackgroundProcessHelpers, rspamd: :server

	config.include HTTPSpamScorer, httpspamscorer: :server
	config.include BackgroundProcessHelpers, httpspamscorer: :server

	config.include SpamExamples, with: :spam_examples

	config.alias_example_group_to :feature
	config.alias_example_to :scenario
end

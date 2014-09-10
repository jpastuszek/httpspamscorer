Given /^rspamd backend$/ do |name|
	@rspam = background_proces('features/support/rspamd') do
		with_argument '--no-fork'
		with_argument '--no-debug'
		with_argument '--no-insecure'
		with_option '--pid' => 'rspamd.pid'
		with_option '--config' => '<project directory>/features/support/rspamd.conf'
	end
	.ready_when_config_includes 'main: calling sigsuspend'
	.instance
	.start
	.wait_ready
end

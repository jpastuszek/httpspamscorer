$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
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

	let :gmail_headers do
		JSON.parse(
			'[["X-Envelope-From", "<jpastuszek@whatclinic.com>"], ["Received", "from mail-we0-f182.google.com (mail-we0-f182.google.com [74.125.82.182]) by mxa.mailgun.org with ESMTP id 5424368c.6947b70-in3; Thu, 25 Sep 2014 15:36:44 -0000 (UTC)"], ["Received", "by mail-we0-f182.google.com with SMTP id u57so6262384wes.13 for <test@sandboxaa5c302b487f44fe90ee9479494fbb1c.mailgun.org>; Thu, 25 Sep 2014 08:36:43 -0700 (PDT)"], ["X-Google-Dkim-Signature", "v=1; a=rsa-sha256; c=relaxed/relaxed; d=1e100.net; s=20130820; h=x-gm-message-state:from:content-type:subject:message-id:date:to :mime-version; bh=sIAKL3nNcLXNyQZPWUjtOQcrbKAb4tSS9xC72m/8Rcw=; b=ZdmMyBeE7FSFGsXLAUKLXgRMMVQmdfBjjkXtqvhJ3ZKArLn+oqnF3na4X5+L5EQk57 RNEehqFSXUY8Yd9TZxyf0GX2zd804slL9+NWzc8/uvS0RZQ1aq2FODFvQpYqT6EWsztM kyVYVBlFGZ977PmxubxaogpImBmUwbQNHXGpDJnYK/aq/zst4BCJNb0TcX7Muf+YaI6B eh2XzrNvNmxqETe9Xa30vETQtXxK8CIR9y+F3avqhNKpGv0vcllq54IQlKkaeUxb1vTI Rs8lr7BZVktbz8zyrtiKdxBWuStL8AunKaO0PQq+KkdEAOdmYajO1WNqylcTK1kvWOp8 ts2w=="], ["X-Gm-Message-State", "ALoCoQkMV/zSEPFSdnSfl/dLvfebYhkQhcgLf7ouBZ/kIfvvruP136RasOyOQ5T7uNo/C3ZH+TjS"], ["X-Received", "by 10.194.78.101 with SMTP id a5mr4184276wjx.118.1411659403469; Thu, 25 Sep 2014 08:36:43 -0700 (PDT)"], ["Return-Path", "<jpastuszek@whatclinic.com>"], ["Received", "from [192.168.1.115] ([86.43.88.8]) by mx.google.com with ESMTPSA id t9sm3066150wjf.41.2014.09.25.08.36.42 for <test@sandboxaa5c302b487f44fe90ee9479494fbb1c.mailgun.org> (version=TLSv1 cipher=ECDHE-RSA-RC4-SHA bits=128/128); Thu, 25 Sep 2014 08:36:42 -0700 (PDT)"], ["From", "\"WhatClinic.com\" <jpastuszek@whatclinic.com>"], ["Content-Type", "multipart/signed; boundary=\"Apple-Mail=_AFFC30E8-7E87-4DA5-A532-A8CBC63AEAAE\"; protocol=\"application/pkcs7-signature\"; micalg=\"sha1\""], ["Subject", "test"], ["Message-Id", "<2B1F8E39-4336-4FB0-A54F-4AFB19DF0F81@whatclinic.com>"], ["Date", "Thu, 25 Sep 2014 16:36:40 +0100"], ["To", "test@sandboxaa5c302b487f44fe90ee9479494fbb1c.mailgun.org"], ["Mime-Version", "1.0 (Mac OS X Mail 7.3 \\(1878.6\\))"], ["X-Mailer", "Apple Mail (2.1878.6)"], ["X-Mailgun-Incoming", "Yes"]]',
		)
	end
end

RSpec.configure do |config|
	config.include RSpamdLegacy, rspamd: :legacy
	config.include SpawnProcessHelpers, rspamd: :legacy

	config.include RSpamd, rspamd: :server
	config.include SpawnProcessHelpers, rspamd: :server

	config.include HTTPSpamScorer, httpspamscorer: :server
	config.include SpawnProcessHelpers, httpspamscorer: :server

	config.include SpamExamples, with: :spam_examples

	config.alias_example_group_to :feature
	config.alias_example_to :scenario
end

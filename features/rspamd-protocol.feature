Feature: rspamd email scoring
	In order to use rspamd as backend it needs to be able to score e-mails and lear ham and spam.

	Background:
		Given rspamd backend

	Scenario: Checking spam score
		When I send spam email for scoring
		Then spam score should be higher than 5

	Scenario: Learning spam
		When I send ham email to learn as spam
		And I send ham email for scoring
		Then spam score should be higher than 5

	Scenario: Learning ham
		When I send spam email to learn as spam
		And I send spam email for scoring
		Then spam score should be lower than 5

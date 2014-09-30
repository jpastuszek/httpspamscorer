require 'pp'

class ErrorReporter < Controller
	self.define do
		on error Rack::UnhandledRequest::UnhandledRequestError do |error|
			write_json 404, {error: error}
		end

		on error Unicorn::ClientShutdown do |error|
			log.warn 'client disconnected prematurely', error
			raise error
		end

		on error(
			URI::InvalidURIError,
			ReconstructedMail::ReconstructionError
		) do |error|
			write_json 400, {error: error}
		end

		on error StandardError do |error|
			log.error "unhandled error while processing request: #{env['REQUEST_METHOD']} #{env['SCRIPT_NAME']}[#{env["PATH_INFO"]}]", error
			log.debug {
				out = StringIO.new
				PP::pp(env, out, 200)
				"Request: \n" + out.string
			}

			write_json 500, {error: error, class: error.class.name}
		end
	end
end

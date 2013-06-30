# Compass::Rack

module Compass
  module Rack
    class CORS
      include Goliath::Rack::AsyncMiddleware

      def post_process(env, status, headers, body)
        headers['Access-Control-Allow-Origin'] = '*'
        [status, headers, body]
      end
    end
  end
end

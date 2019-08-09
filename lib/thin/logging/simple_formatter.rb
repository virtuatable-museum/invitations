module Thin
  module Logging
    # Use with thin (re)start --daemonize --trace --require ./lib/thin/logging/simple_formatter.rb
    # TODO : try to call it inside the code to log the response as a whole.
    class SimpleFormatter < Logger::Formatter
      def call(severity, timestamp, progname, msg)
        "-- START --\n#{severity}\n#{timestamp}\n#{msg}\n-- END --\n\n"
      end
    end
  end
end
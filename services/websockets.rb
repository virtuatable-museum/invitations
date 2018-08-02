module Services
  # This service stores informations used to make requests on the websockets.
  # @author Vincent Courtois <courtois.vincent@outlook.com>
  class Websockets
    include Singleton

    # @!attribute [r] application
    #   @return [Arkaan::OAuth::Application] the OAuth application that will be used for requests.
    attr_reader :application

    def initialize
      account = Arkaan::Account.where(username: ENV['USERNAME']).first
      @application = Arkaan::OAuth::Application.find_or_create_by(name: 'invitations', premium: true, creator: account)
      @application.save
    end

    # Makes a request on the messages service so that messgaes are transmitted to the websockets.
    # @param message [String] the type of message you want to send to the websockets.
    # @param data [Hash] additional data to pass with the message.
    def make_request(session, message, data)
      create_connection.post do |request|
        request.url = '/messages'
        request.body = {message: message, data: data, app_key: application.key}.to_json
      end
    end

    # Creates a connection to one of the gateways to send the message to.
    # @param []
    def create_connection
      gateway = Arkaaan::Monitoring::Gateway.where(running: true, active: true).sample
      return Faraday.new(url: gateway.url)
    end
  end
end
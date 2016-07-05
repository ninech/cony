require 'bunny'
require 'json'

module Cony
  class AMQPConnectionHandler

    def initialize(config)
      @config = config
    end

    def publish(message, routing_key)
      Bunny.run(@config) do |connection|
        channel = connection.create_channel
        exchange = channel.topic(@config[:exchange], durable: Cony.config.durable)
        exchange.publish(message.to_json,
                         key: routing_key,
                         mandatory: false,
                         immediate: false,
                         persistent: Cony.config.durable,
                         content_type: 'application/json')
      end
    rescue => error
      Airbrake.notify(error) if defined?(Airbrake)
      Rails.logger.error("#{error.class}: #{error}") if defined?(Rails)
    end

  end
end

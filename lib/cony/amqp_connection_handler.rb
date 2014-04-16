require 'bunny'

module Cony
  class AMQPConnectionHandler

    def initialize(config)
      @config = config
    end

    def publish(message, routing_key)
      Bunny.run(@config) do |connection|
        exchange = connection.exchange(@config[:exchange], type: :topic, durable: true)
        exchange.publish(message.to_json,
                         key: routing_key,
                         mandatory: false,
                         immediate: false,
                         persistent: true,
                         content_type: 'application/json')
      end
    end

  end
end

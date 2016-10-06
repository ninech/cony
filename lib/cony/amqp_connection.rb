require 'bunny'
require 'json'
require 'singleton'

module Cony
  class AMQPConnection
    include Singleton

    def self.publish(message, routing_key)
      instance.publish(message, routing_key)
    end

    def publish(message, routing_key)
      channel = connection.create_channel
      exchange = channel.topic(Cony.config.amqp[:exchange], durable: Cony.config.durable)
      exchange.publish(message.to_json,
                       key: routing_key,
                       mandatory: false,
                       immediate: false,
                       persistent: Cony.config.durable,
                       content_type: 'application/json')
    rescue => error
      Airbrake.notify(error) if defined? Airbrake
      Rails.logger.error("#{error.class}: #{error}") if defined? Rails
    end

    private

    def connection
      return @connection unless @connection.nil? || @connection.closed?

      @connection = Bunny.new Cony.config.amqp
      ObjectSpace.define_finalizer(self, proc { cleanup })
      @connection.start
    end

    def cleanup
      @connection.close unless @connection.closed?
    end
  end
end

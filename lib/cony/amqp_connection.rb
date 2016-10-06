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

    def connection=(connection)
      @connection = connection if invalid_connection?
    end

    def connection
      return @connection if valid_connection?

      @connection = Bunny.new Cony.config.amqp
      ObjectSpace.define_finalizer(self, proc { cleanup })
      @connection.start
    end

    def invalid_connection?
      @connection.nil? || @connection.closed?
    end

    def valid_connection?
      !invalid_connection?
    end

    private

    def cleanup
      @connection.close if valid_connection?
    end
  end
end

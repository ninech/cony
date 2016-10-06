require 'bunny'
require 'json'

module Cony
  class AMQPConnectionHandler
    def initialize(config, connection = nil)
      @config = config
      @connection = connection

      @connection.start unless @connection.nil? || @connection.open?
    end

    def publish(message, routing_key)
      channel = connection.create_channel
      exchange = channel.topic(@config[:exchange], durable: Cony.config.durable)
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

      @connection = Bunny.new @config
      ObjectSpace.define_finalizer(self, proc { cleanup })
      @connection.start
    end

    def cleanup
      @connection.close unless @connection.closed?
    end
  end
end

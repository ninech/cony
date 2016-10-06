require 'bunny'
require 'json'
require 'singleton'

module Cony
  ##
  # The only place in cony that deals with AMQP connection and it's lifecycle
  class AMQPConnection
    include Singleton

    ##
    # Shorthand for +Cony::AMQPConnection.instance.publish+
    def self.publish(message, routing_key)
      instance.publish(message, routing_key)
    end

    ##
    # :category: Internal
    # Sends the status change message to the configured AMQP destination
    def publish(message, routing_key)
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

    ##
    # Sets a custom connection if no valid_connection? is already provided
    def connection=(connection)
      @connection = connection if invalid_connection?
    end

    ##
    # Returns the existing connection or creates a new connection
    def connection
      return @connection if valid_connection?

      @connection = Bunny.new Cony.config.amqp
      ObjectSpace.define_finalizer(self, proc { cleanup })
      @connection.start
    end

    ##
    # +true+ if there's currently no connection or the connection has been closed
    def invalid_connection?
      @connection.nil? || @connection.closed?
    end

    ##
    # +false+ if invalid_connection? is +true+
    def valid_connection?
      !invalid_connection?
    end

    private

    def exchange
      connection.
        create_channel.
        topic(Cony.config.amqp[:exchange], durable: Cony.config.durable)
    end

    def cleanup
      @connection.close if valid_connection?
    end
  end
end

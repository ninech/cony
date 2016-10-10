require 'bunny'
require 'json'
require 'singleton'
require 'cony/valid_connection_already_defined'

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
    # :deprecated: Use the Cony Initializer
    def connection=(connection)
      fail Cony::ValidConnectionAlreadyDefined, 'A connection has already been set.' if valid_connection_present?
      @connection = connection
    end

    ##
    # Returns the existing connection or creates a new connection
    def connection
      return @connection if valid_connection_present?

      return @connection = Cony.config.amqp_connection unless Cony.config.amqp_connection.nil?

      @connection = Bunny.new(Cony.config.amqp)
      ObjectSpace.define_finalizer(self, proc { cleanup })
      @connection.start
    end

    ##
    # +false+ if invalid_connection? is +true+
    def valid_connection_present?
      !@connection.nil? && @connection.open?
    end

    private

    def exchange
      connection.
        create_channel.
        topic(Cony.config.amqp[:exchange], durable: Cony.config.durable)
    end

    def cleanup
      @connection.close if valid_connection_present?
    end
  end
end

require 'active_support/core_ext/string/inflections'

require 'cony'
require 'cony/amqp_connection_handler'

module Cony
  module ActiveRecord

    extend ActiveSupport::Concern

    included do
      after_create :cony_send_create_notify
      after_update :cony_send_update_notify
      after_destroy :cony_send_destroy_notify
    end

    def cony_send_create_notify
      publish(:created)
    end

    def cony_send_update_notify
      publish(:updated)
    end

    def cony_send_destroy_notify
      publish(:destroyed)
    end


    private
    def publish(type)
      return if Cony.config.test_mode
      amqp_connection.publish(
        {id: self.id, changes: cony_changes, model: self.class.name, event: type},
        "#{self.class.name.underscore}.mutation.#{type}")
    end

    def amqp_connection
      @amqp_connection ||= Cony::AMQPConnectionHandler.new(Cony.config.amqp)
    end

    def cony_changes
      changes.map do |name, change|
        {name => {old: change.first, new: change.last}}
      end
    end

  end
end

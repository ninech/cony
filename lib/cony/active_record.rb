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
      after_touch :cony_send_touch_notify
    end

    def cony_send_create_notify
      publish(:create)
    end

    def cony_send_update_notify
      publish(:update)
    end

    def cony_send_destroy_notify
      publish(:destroy)
    end

    def cony_send_touch_notify
      publish(:touch)
    end


    private
    def publish(type)
      amqp_connection.publish(
        {id: self.id, changes: cony_changes},
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

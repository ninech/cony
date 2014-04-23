require 'active_support/core_ext/string/inflections'

require 'cony'
require 'cony/amqp_connection_handler'

module Cony
  module ActiveRecord

    extend ActiveSupport::Concern

    included do
      after_create :cony_save_create_notify_data
      after_update :cony_save_update_notify_data
      after_destroy :cony_save_destroy_notify_data
      after_commit :cony_publish
    end

    def cony_save_create_notify_data
      @cony_notify = { event: :created, changes: cony_changes_created }
    end

    def cony_save_update_notify_data
      @cony_notify = { event: :updated, changes: cony_changes_updated }
    end

    def cony_save_destroy_notify_data
      @cony_notify = { event: :destroyed, changes: cony_changes_destroyed }
    end

    def cony_publish
      return if Cony.config.test_mode
      cony_amqp_connection.publish(
        {id: self.id, changes: @cony_notify[:changes], model: self.class.name, event: @cony_notify[:event]},
        "#{self.class.name.underscore}.mutation.#{@cony_notify[:event]}")
    end

    private
    def cony_amqp_connection
      @cony_amqp_connection ||= Cony::AMQPConnectionHandler.new(Cony.config.amqp)
    end

    def cony_mapped_changes
      changes.map do |name, change|
        {name => {old: change.first, new: change.last}}
      end
    end

    def cony_changes_created
      cony_mapped_changes
    end

    def cony_changes_updated
      cony_mapped_changes
    end

    def cony_changes_destroyed
      attributes.map do |name, value|
        {name => {old: value, new: nil}}
      end
    end
  end
end

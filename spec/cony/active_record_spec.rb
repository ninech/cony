require 'spec_helper'

require 'cony/active_record'

describe Cony::ActiveRecord do
  let(:amqp_connection) { double('Cony::AMQPConnection') }
  let(:id) { 1337 }
  let(:active_record_changes) { { name: %w(old new) } }
  let(:active_record_attributes) { { name: 'value' } }
  let(:cony_changes) { [{ name: { old: 'old', new: 'new' } }] }
  let(:expected_payload) do
    {
      id: id,
      changes: cony_changes,
      model: 'Anonymaus::Klass',
      event: event,
    }
  end

  let(:model) do
    eval <<-EOF
      Class.new do
        def self.after_create(callback); end
        def self.after_update(callback); end
        def self.after_destroy(callback); end
        def self.after_commit(callback); end
        def self.name; "Anonymaus::Klass"; end
        def id; #{id}; end
        def changes; #{active_record_changes}; end
        def attributes; #{active_record_attributes}; end

        include Cony::ActiveRecord
      end
    EOF
  end

  before do
    allow(Cony::AMQPConnection).to receive(:instance).and_return(amqp_connection)
  end

  subject { model.new }

  describe '#cony_send_create_notify' do
    let(:event) { :created }
    it 'uses the amqp connection to send the notify' do
      expect(amqp_connection).to receive(:publish).with(expected_payload, 'anonymaus/klass.mutation.created')
      subject.cony_save_create_notify_data
      subject.cony_publish
    end
  end

  describe '#cony_send_update_notify' do
    let(:event) { :updated }
    it 'uses the amqp connection to send the notify' do
      expect(amqp_connection).to receive(:publish).with(expected_payload, 'anonymaus/klass.mutation.updated')
      subject.cony_save_update_notify_data
      subject.cony_publish
    end
  end

  describe '#cony_send_destroy_notify' do
    let(:event) { :destroyed }
    let(:cony_changes) { [{ name: { old: 'value', new: nil } }] }
    it 'uses the amqp connection to send the notify' do
      expect(amqp_connection).to receive(:publish).with(expected_payload, 'anonymaus/klass.mutation.destroyed')
      subject.cony_save_destroy_notify_data
      subject.cony_publish
    end
  end

  context 'test mode enabled' do
    before do
      allow(Cony.config).to receive(:test_mode).and_return(true)
    end
    it 'does not send the message' do
      expect(Cony::AMQPConnection).to_not receive(:instance)
      subject.cony_save_create_notify_data
      subject.cony_publish
    end
  end
end

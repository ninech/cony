require 'spec_helper'

require 'cony/active_record'

describe Cony::ActiveRecord do

  let(:amqp_connection) { double('Cony::AMQPConnectionHandler') }
  let(:id) { 1337 }
  let(:active_record_changes) { {name: ['old', 'new']} }
  let(:cony_changes) { [{name: {old: 'old', new: 'new'}}] }
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
        def self.name; "Anonymaus::Klass"; end
        def id; #{id}; end
        def changes; #{active_record_changes}; end

        include Cony::ActiveRecord
      end
    EOF
  end

  before do
    Cony::AMQPConnectionHandler.stub(:new).and_return(amqp_connection)
  end

  subject { model.new }

  describe '#cony_send_create_notify' do
    let(:event) { :created }
    it 'uses the amqp connection to send the notify' do
      amqp_connection.should_receive(:publish).with(expected_payload, 'anonymaus/klass.mutation.created')
      subject.cony_send_create_notify
    end
  end

  describe '#cony_send_update_notify' do
    let(:event) { :updated }
    it 'uses the amqp connection to send the notify' do
      amqp_connection.should_receive(:publish).with(expected_payload, 'anonymaus/klass.mutation.updated')
      subject.cony_send_update_notify
    end
  end

  describe '#cony_send_destroy_notify' do
    let(:event) { :destroyed }
    it 'uses the amqp connection to send the notify' do
      amqp_connection.should_receive(:publish).with(expected_payload, 'anonymaus/klass.mutation.destroyed')
      subject.cony_send_destroy_notify
    end
  end

  context 'test mode enabled' do
    before do
      Cony.config.stub(:test_mode).and_return(true)
    end
    it 'does not send the message' do
      expect(Cony::AMQPConnectionHandler).to_not receive(:new)
      subject.cony_send_create_notify
    end
  end

end

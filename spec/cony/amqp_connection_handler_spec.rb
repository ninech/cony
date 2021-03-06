require 'spec_helper'
require 'ostruct'

require 'cony/amqp_connection_handler'

describe Cony::AMQPConnectionHandler do
  let(:config) { { exchange: 'bunny-tests' } }
  let(:handler) { Cony::AMQPConnectionHandler.new(config) }
  let(:message) { 'Bunnies are connies' }
  let(:routing_key) { 'bunny.info' }
  let(:exchange_double) do
    double('Exchange double').tap do |exc|
      allow(exc).to receive(:publish)
    end
  end
  let(:channel_double) do
    double('Channel double').tap do |channel|
      allow(channel).to receive(:topic).and_return(exchange_double)
    end
  end
  let(:connection_double) do
    double('Connection double').tap do |conn|
      allow(conn).to receive(:create_channel).and_return(channel_double)
    end
  end

  subject { handler }

  before do
    allow(Bunny).to receive(:run).and_yield(connection_double)
  end

  it 'uses bunny to publish a message' do
    expect(Bunny).to receive(:run)
    subject.publish(message, routing_key)
  end

  it 'configures the exchange correctly' do
    expect(channel_double).to receive(:topic).with('bunny-tests', durable: false)
    subject.publish(message, routing_key)
  end

  it 'publishes the message' do
    publish_options = {
      key: routing_key,
      mandatory: false,
      immediate: false,
      persistent: false,
      content_type: 'application/json',
    }
    expect(exchange_double).to receive(:publish).
      with('"Bunnies are connies"', publish_options)
    subject.publish(message, routing_key)
  end

  describe 'error handling' do
    before do
      allow(Bunny).to receive(:run).and_raise('I failed so hard')
    end

    it 'does not raise an error' do
      expect { subject.publish(message, routing_key) }.to_not raise_error
    end

    context 'Rails loaded' do
      before do
        stub_const('Rails', OpenStruct.new(logger: double('Railslogger')))
      end
      it 'logs an error' do
        expect(Rails.logger).to receive(:error).with('RuntimeError: I failed so hard')
        subject.publish(message, routing_key)
      end
    end

    context 'Sentry loaded' do
      before do
        stub_const('Raven', double('Raven'))
      end
      it 'sends the error' do
        expect(Raven).to receive(:capture_exception).with(instance_of(RuntimeError))
        subject.publish(message, routing_key)
      end
    end
  end
end

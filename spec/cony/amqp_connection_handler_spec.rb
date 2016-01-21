require 'spec_helper'
require 'ostruct'

require 'cony/amqp_connection_handler'

describe Cony::AMQPConnectionHandler do

  let(:config) { {exchange: 'bunny-tests'} }
  let(:handler) { Cony::AMQPConnectionHandler.new(config) }
  let(:message) { 'Bunnies are connies' }
  let(:routing_key) { 'bunny.info' }
  let(:exchange_double) do
    double('Exchange double').tap do |exc|
      exc.stub(:publish)
    end
  end
  let(:channel_double) do
    double('Channel double').tap do |channel|
      channel.stub(:topic).and_return(exchange_double)
    end
  end
  let(:connection_double) do
    double('Connection double').tap do |conn|
      conn.stub(:create_channel).and_return(channel_double)
    end
  end

  subject { handler }

  before do
    Bunny.stub(:run).and_yield(connection_double)
  end

  it 'uses bunny to publish a message' do
    Bunny.should_receive(:run)
    subject.publish(message, routing_key)
  end

  it 'configures the exchange correctly' do
    channel_double.should_receive(:topic).with('bunny-tests', durable: false)
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
    exchange_double.should_receive(:publish)
      .with('"Bunnies are connies"', publish_options)
    subject.publish(message, routing_key)
  end

  describe 'error handling' do
    before do
      Bunny.stub(:run).and_raise('I failed so hard')
    end

    it 'does not raise an error' do
      expect { subject.publish(message, routing_key) }.to_not raise_error
    end

    context 'Rails loaded' do
      before do
        stub_const('Rails', OpenStruct.new(logger: double('Railslogger')))
      end
      it 'logs an error' do
        expect(Rails.logger).to receive(:error).with("RuntimeError: I failed so hard")
        subject.publish(message, routing_key)
      end
    end

    context 'Airbrake loaded' do
      before do
        stub_const('Airbrake', double('Airbrake'))
      end
      it 'sends the error' do
        expect(Airbrake).to receive(:notify_or_ignore).with(instance_of(RuntimeError))
        subject.publish(message, routing_key)
      end
    end
  end

end

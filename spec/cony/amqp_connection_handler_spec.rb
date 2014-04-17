require 'spec_helper'

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
  let(:connection_double) do
    double('Connection double').tap do |conn|
      conn.stub(:exchange).and_return(exchange_double)
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
    connection_double.should_receive(:exchange).with('bunny-tests', type: :topic, durable: false)
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

end
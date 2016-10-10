require 'spec_helper'
require 'ostruct'

require 'cony/amqp_connection'
require 'cony/valid_connection_already_defined'

describe Cony::AMQPConnection do
  let(:amqp_config) { { exchange: 'bunny-tests' } }
  let(:config) { double('Cony Config', amqp: amqp_config, durable: false, amqp_connection: nil) }
  let(:handler) { Cony::AMQPConnection }
  let(:message) { 'Bunnies are connies' }
  let(:routing_key) { 'bunny.info' }
  let(:exchange_double) do
    double('Exchange double').tap do |exc|
      allow(exc).to receive(:publish)
    end
  end
  let(:channel_double) { double('Channel double', topic: exchange_double) }
  let(:connection_double) do
    double('Bunny::Session', closed?: false, open?: true, create_channel: channel_double).tap do |conn|
      allow(conn).to receive(:start).and_return conn
    end
  end

  subject do
    # clone is necessary, because AMQPConnection is a Singleton
    handler.clone
  end

  before do
    allow(Bunny).to receive(:new).and_return connection_double
    allow(Cony).to receive(:config).and_return config
  end

  it 'creates a new bunny session' do
    expect(Bunny).to receive(:new).and_return(connection_double)
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
    expect(exchange_double).to receive(:publish).with('"Bunnies are connies"', publish_options)
    subject.publish(message, routing_key)
  end

  it 'reuses bunny session' do
    expect(Bunny).to receive(:new).and_return(connection_double).once
    subject.publish(message, routing_key)
    subject.publish(message, routing_key)
  end

  describe 'error handling' do
    before do
      allow(Bunny).to receive(:new).and_raise('I failed so hard')
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

    context 'Airbrake loaded' do
      before do
        stub_const('Airbrake', double('Airbrake'))
      end
      it 'sends the error' do
        expect(Airbrake).to receive(:notify).with(instance_of(RuntimeError))
        subject.publish(message, routing_key)
      end
    end
  end

  describe 'setting a connection' do
    let(:existing_connection) { connection_double.clone }

    describe 'on the AmqpConnection (deprecated)' do
      it 'sets the connection to the given one' do
        subject.instance.connection = existing_connection

        expect(subject.instance.connection).to be(existing_connection)
      end

      it 'raises exception when redefining the connection' do
        expect(subject.instance.connection).to be(connection_double)
        expect { subject.instance.connection = existing_connection }.
          to raise_error(Cony::ValidConnectionAlreadyDefined)
      end
    end

    describe 'through the config' do
      let(:config) do
        double('Cony Config', amqp: amqp_config, durable: false, amqp_connection: existing_connection)
      end

      it 'uses the connection from the config' do
        expect(subject.instance.connection).to be(existing_connection)
      end

      it 'raises exception when redefining the connection' do
        expect(subject.instance.connection).to be(existing_connection)
        expect { subject.instance.connection = existing_connection }.
          to raise_error(Cony::ValidConnectionAlreadyDefined)
      end

      describe 'no amqp config hash given' do
        let(:config) do
          double('Cony Config', amqp: nil, durable: false, amqp_connection: existing_connection)
        end

        it 'still uses the connection from the config' do
          expect(subject.instance.connection).to be(existing_connection)
        end
      end
    end
  end
end

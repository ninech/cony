require 'spec_helper'

require "active_record"
require 'cony/active_record'

class MyModel < ActiveRecord::Base
  include Cony::ActiveRecord
end

describe 'Integration' do
  describe Cony::ActiveRecord do
    before do
      ActiveRecord::Base.establish_connection(
        adapter: "sqlite3",
        database: ":memory:"
      )

      ActiveRecord::Schema.verbose = false
      ActiveRecord::Schema.define do
        create_table :my_models do |table|
          table.column :title, :string
          table.column :num, :integer
        end
      end

      allow(Cony::AMQPConnectionHandler).to receive(:new).and_return(amqp_connection)
      allow(amqp_connection).to receive(:publish)
    end

    let(:amqp_connection) { double('Cony::AMQPConnectionHandler') }

    let(:title) { 'Sansibar' }
    let(:num) { 21 }

    subject { MyModel.new title: title, num: num }

    describe 'Create new MyModel' do
      let(:event) { :created }

      it 'sends a message' do
        expect(amqp_connection).to receive(:publish)
        subject.save
      end

      it 'sets the routing_key' do
        expect(amqp_connection).to receive(:publish) do |payload, key|
          expect(key).to eq("my_model.mutation.#{event}")
        end

        subject.save
      end

      it 'sets the correct id' do
        expect(amqp_connection).to receive(:publish) do |payload, key|
          expect(payload[:id]).to eq(subject.id)
        end

        subject.save
      end

      it 'sets the correct model' do
        expect(amqp_connection).to receive(:publish) do |payload, key|
          expect(payload[:model]).to eq(subject.class.name)
        end

        subject.save
      end

      it 'sets the correct event type' do
        expect(amqp_connection).to receive(:publish) do |payload, key|
          expect(payload[:event]).to eq(event)
        end

        subject.save
      end

      it 'contains the changes' do
        expect(amqp_connection).to receive(:publish) do |payload, key|
          expect(payload[:changes]).to include({"id"=>{old: nil, new: subject.id}})
          expect(payload[:changes]).to include({"title"=>{old: nil, new: title}})
          expect(payload[:changes]).to include({"num"=>{old: nil, new: num}})
        end

        subject.save
      end

      it 'contains the only the changes' do
        expect(amqp_connection).to receive(:publish) do |payload, key|
          expect(payload[:changes].count).to eq(3)
        end

        subject.save
      end
    end

    describe 'Update a MyModel' do
      before { subject.save }

      let(:event) { :updated }
      let(:new_title) { 'Tristan da Cunha' }

      it 'sends a message' do
        expect(amqp_connection).to receive(:publish)
        subject.title = new_title
        subject.save
      end

      it 'sets the routing_key' do
        expect(amqp_connection).to receive(:publish) do |payload, key|
          expect(key).to eq("my_model.mutation.#{event}")
        end

        subject.title = new_title
        subject.save
      end

      it 'sets the correct id' do
        expect(amqp_connection).to receive(:publish) do |payload, key|
          expect(payload[:id]).to eq(subject.id)
        end

        subject.title = new_title
        subject.save
      end

      it 'sets the correct model' do
        expect(amqp_connection).to receive(:publish) do |payload, key|
          expect(payload[:model]).to eq(subject.class.name)
        end

        subject.title = new_title
        subject.save
      end

      it 'sets the correct event type' do
        expect(amqp_connection).to receive(:publish) do |payload, key|
          expect(payload[:event]).to eq(event)
        end

        subject.title = new_title
        subject.save
      end

      it 'contains the changes' do
        expect(amqp_connection).to receive(:publish) do |payload, key|
          expect(payload[:changes]).to include({"title"=>{old: title, new: new_title}})
        end

        subject.title = new_title
        subject.save
      end

      it 'contains the only the changes' do
        expect(amqp_connection).to receive(:publish) do |payload, key|
          expect(payload[:changes].count).to eq(1)
        end

        subject.title = new_title
        subject.save
      end
    end

    describe 'Delete a MyModel' do
      before { subject.save }

      let(:event) { :destroyed }

      it 'sends a message' do
        expect(amqp_connection).to receive(:publish)
        subject.destroy
      end

      it 'sets the routing_key' do
        expect(amqp_connection).to receive(:publish) do |payload, key|
          expect(key).to eq("my_model.mutation.#{event}")
        end

        subject.destroy
      end

      it 'sets the correct id' do
        expect(amqp_connection).to receive(:publish) do |payload, key|
          expect(payload[:id]).to eq(subject.id)
        end

        subject.destroy
      end

      it 'sets the correct model' do
        expect(amqp_connection).to receive(:publish) do |payload, key|
          expect(payload[:model]).to eq(subject.class.name)
        end

        subject.destroy
      end

      it 'sets the correct event type' do
        expect(amqp_connection).to receive(:publish) do |payload, key|
          expect(payload[:event]).to eq(event)
        end

        subject.destroy
      end

      it 'contains the changes' do
        expect(amqp_connection).to receive(:publish) do |payload, key|
          expect(payload[:changes]).to include({"id"=>{old: subject.id, new: nil}})
          expect(payload[:changes]).to include({"title"=>{old: title, new: nil}})
          expect(payload[:changes]).to include({"num"=>{old: num, new: nil}})
        end

        subject.destroy
      end

      it 'contains the only the changes' do
        expect(amqp_connection).to receive(:publish) do |payload, key|
          expect(payload[:changes].count).to eq(3)
        end

        subject.destroy
      end
    end
  end
end

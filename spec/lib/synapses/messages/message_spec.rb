# coding: utf-8

require 'spec_helper'

describe Synapses::Messages::Message do
  describe 'class' do
    subject { described_class }

    describe 'AMQP metadata' do
      it { should respond_to(:routing_key) }
      it { should respond_to(:message_type) }
      it { should respond_to(:mandatory) }
      it { should respond_to(:immediate) }
      it { should respond_to(:persistent) }
      it { should respond_to(:content_type) }
    end

    describe 'structure' do
      it { should respond_to(:attributes) }
      it { should respond_to(:attribute) }
    end
  end

  describe 'instance' do
    it { should respond_to(:attributes) }
    it { should respond_to(:metadata) }
    it { should respond_to(:header) }
    it { should respond_to(:raw_payload) }

    context 'delegate to AMQP::Header' do
      context 'methods:' do
        it { should respond_to(:ack) }
        it { should respond_to(:reject) }
      end

      context 'attributes:' do
        it { should respond_to(:reply_to) }
        it { should respond_to(:message_id) }
        it { should respond_to(:correlation_id) }
      end
    end
  end

  describe '.new' do
    let(:attributes) { {} }
    let(:metadata) { {} }
    subject(:message) { described_class.new(attributes, metadata) }

    its(:to_s) { should == '{}' }

    context 'coders' do
      context 'application/json' do
        let(:attributes) { '{"something":"another","anything":"nothing","number":0}' }
        let(:metadata) { {routing_key: 'synapses.examples.a.b.c'} }

        its(:attributes) { should == {'something' => 'another', 'anything' => 'nothing', 'number' => 0} }
        its(:metadata) do
          should == {
            content_type: 'application/json',
            immediate: false,
            mandatory: false,
            persistent: false,
            routing_key: 'synapses.examples.a.b.c',
            type: nil
          }
        end
        its(:to_s) { should == attributes }
      end

      context 'text/x-yaml' do
        let(:ruby_hash) { {one: :a, two: 'b', three: 3} }

        let(:attributes) { "---\n:one: :a\n:two: b\n:three: 3\n" }
        let(:metadata) { {content_type: 'text/x-yaml', persistent: true} }

        its(:attributes) { should == ruby_hash }
        its(:metadata) do
          should == {
            content_type: 'text/x-yaml',
            immediate: false,
            mandatory: false,
            persistent: true,
            routing_key: nil,
            type: nil
          }
        end
        its(:to_s) { should == attributes }
      end
    end

    context 'AMQP::Header' do
      let(:channel) do
        channel = double(AMQP::Channel)
        channel.stub(:acknowledge).with('delivery_tag', false).and_return(true)
        channel.stub(:reject).with('delivery_tag', false).and_return(true)
        channel
      end
      let(:method) do
        method = double(AMQ::Protocol::Method)
        method.stub(:delivery_tag).and_return('delivery_tag')
        method.stub(:consumer_tag).and_return('consumer_tag')
        method
      end
      let(:metadata) do
        AMQP::Header.new(
          channel,
          method,
          {
            reply_to: 'reply_to',
            message_id: 'message_id',
            correlation_id: 'correlation_id',
            routing_key: 'synapses.examples.a.b.c',
          }
        )
      end

      its(:reply_to) { should == 'reply_to' }
      its(:message_id) { should == 'message_id' }
      its(:correlation_id) { should == 'correlation_id' }
      its(:ack) { should == true }
      its(:reject) { should == true }
      its(:routing_key) { should == 'synapses.examples.a.b.c' }
    end
  end
end

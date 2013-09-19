require 'synapses/contract'
require 'synapses/contract/connectible'
require 'amqp/queue'

module Synapses
  class Contract
    # @author Alexander Semyonov <al@semyonov.us>
    class Queue
      # @return [String]
      attr_accessor :name

      # @return [Hash] see {AMQP::Queue#initialize}
      attr_accessor :options

      # @param [String] name
      # @param [Hash] options see {AMQP::Queue#initialize}
      def initialize(name, options = {})
        @name = name
        @bind = options.delete('bind') { raise "Exchange :bind is not specified for queue #{name}" }
        @options = options || {}
      end

      # @return [AMQP::Channel]
      attr_accessor :channel
      def channel
        @channel ||= Synapses.default_channel
      end

      # @return [AMQP::Queue]
      def connect(channel=self.channel)
        @queue = AMQP::Queue.new(channel, name, options)
      end

      # @return [Boolean]
      def connected?
        !!@queue
      end

      # @param [AMQP::Channel] channel
      # @return [AMQP::Queue]
      def queue(channel=self.channel)
        connect(channel) unless connected?
        @queue
      end
    end
  end
end

require 'synapses/contract'
require 'synapses/contract/connectible'

module Synapses
  class Contract
    # @author Alexander Semyonov <al@semyonov.us>
    class Exchange
      # @return [String]
      attr_accessor :name
      # @return ['direct', 'topic', 'fanout', 'headers']
      attr_accessor :type
      # @return [Hash]
      attr_accessor :options

      # @param [String] name
      # @param [Hash] options see {AMQP::Exchange}
      def initialize(name, options = {})
        @name = name
        @type = options.delete('type') { raise "Type for exchange #{name} is not set" }
        @options = options || {}
      end

      # @return [AMQP::Channel]
      attr_accessor :channel
      def channel
        @channel ||= Synapses.default_channel
      end

      # @param [AMQP::Channel] channel
      # @return [AMQP::Exchange]
      def connect(channel)
        @exchange = AMQP::Exchange.new(channel, type, name, options)
      end

      # @return [Boolean]
      def connected?
        !!@queue
      end

      # @param [AMQP::Channel] channel
      # @return [AMQP::Exchange]
      def exchange(channel=self.channel)
        connect(channel) unless connected?
        @exchange
      end
    end
  end
end

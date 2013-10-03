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

      # @param [String] name
      # @param [Hash] options see {AMQP::Exchange}
      def initialize(name, options = {})
        @name = name
        @namespace = options.delete('namespace')
        @type = options.delete('type') { raise "Type for exchange #{name} is not set" }.to_sym
        @options = options || {}
      end

      def instance_attributes
        [type, name, options]
      end

      # @return [Hash] see {AMQP::Exchange#initialize}
      def options
        @options.symbolize_keys
      end

      # @return [Boolean]
      def system?
        @namespace == 'amq'
      end
    end
  end
end

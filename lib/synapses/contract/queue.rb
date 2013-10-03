require 'synapses/contract'
require 'synapses/contract/connectible'
require 'amqp/queue'

module Synapses
  class Contract
    # @author Alexander Semyonov <al@semyonov.us>
    class Queue
      # @return [String]
      attr_accessor :name

      # @return [<String>]
      attr_accessor :bindings

      # @param [String] name
      # @param [Hash] options see {AMQP::Queue#initialize}
      def initialize(name, options = {})
        @name = name
        @namespace = options.delete('namespace')
        if options.key?('binding')
          @bindings = [options.delete('binding')]
        else
          @bindings = options.delete('bindings') { raise "Bindings are not specified for queue #{name}" }
        end
        if @bindings.is_a?(Array)
          @bindings = @bindings.inject({}) do |result, exchange|
            result[exchange] = {}
            result
          end
        end
        @options = options || {}
      end

      def instance_attributes
        [name, options]
      end

      # @return [Hash] see {AMQP::Queue#initialize}
      def options
        @options.symbolize_keys
      end

      def system?
        @namespace == 'amq'
      end
    end
  end
end

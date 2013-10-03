# coding: utf-8

require 'synapses/contract'

module Synapses
  class Contract
    class MessageType
      # @return [String]
      attr_accessor :type

      # @return [Hash]
      attr_accessor :options

      # @param [String] type
      # @param [Hash] options
      def initialize(type, options)
        @type = type
        @options = options
      end

      def class_name
        @class_name ||= options.delete('class_name') { type.split(/\./).last }.classify
      end

      def schema
        @schema ||= options.delete('schema')
      end
    end
  end
end

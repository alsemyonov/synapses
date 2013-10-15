# coding: utf-8

require 'synapses/producer'

module Synapses
  class Producer
    class RoutingProxy
      # @param [#publish] producer
      # @param [String] routing_key
      def initialize(producer, routing_key)
        @producer, @routing_key = producer, routing_key
      end

      # @return [String]
      attr_reader :routing_key
      # @return [Producer]
      attr_reader :producer

      # @param [Synapses::Messages::Message] message
      # @param [Hash] metadata
      def publish(message, metadata = {})
        message = message
        metadata[:routing_key] = routing_key
        producer.publish(message, metadata)
      end
      alias << publish
    end
  end
end

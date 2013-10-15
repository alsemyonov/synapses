# coding: utf-8

require 'synapses/producer'
require 'synapses/producer/routing_proxy'

module Synapses
  class Producer
    module Routable
      # @param [String] routing_key
      def [](routing_key)
        routing_proxies[routing_key]
      end

      private

      def routing_proxies
        @routing_proxies ||= Hash.new { |registry, routing_key| registry[routing_key] = RoutingProxy.new(self, routing_key) }
      end
    end
  end
end

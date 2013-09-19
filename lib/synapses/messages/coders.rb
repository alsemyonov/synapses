require 'synapses/messages/coders'
require 'multi_json'

module Synapses
  module Messages
    # @author Alexander Semyonov <al@semyonov.us>
    module Coders
      module_function

      class << self
        attr_accessor :coders
      end
      self.coders = {}

      if defined?(::MultiJson)
        coders['application/json'] = MultiJson
      end

      # @param [String] payload
      # @param [String] content_type
      # @return [Hash] +payload+ decoded from +content_type+
      def decode(payload, content_type)
        coders[content_type.to_s].decode(payload)
      end

      # @param [Hash] payload
      # @param [String] content_type
      # @return [String] +payload+ encoded as +content_type+
      def encode(payload, content_type)
        coders[content_type.to_s].encode(payload)
      end
    end
  end
end

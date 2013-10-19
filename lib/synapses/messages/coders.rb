require 'synapses/messages/coders'
require 'yaml'
require 'json'

module Synapses
  module Messages
    # @author Alexander Semyonov <al@semyonov.us>
    module Coders
      module_function

      class << self
        attr_accessor :coders
      end
      self.coders = {}
      coders['text/x-yaml'] = Class.new do
        def decode(payload)
          YAML.load(payload)
        end

        def encode(payload)
          YAML.dump(payload)
        end
      end.new
      coders['application/json'] = Class.new do
        def decode(payload)
          JSON.parse(payload)
        end

        def encode(payload)
          JSON.generate(payload)
        end
      end.new

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

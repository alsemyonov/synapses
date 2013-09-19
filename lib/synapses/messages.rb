require 'synapses'
require 'json'

module Synapses
  # @author Alexander Semyonov <al@semyonov.us>
  module Messages
    extend ActiveSupport::Concern

    def self.registry
      @registry ||= {}
    end

    # @param [AMQP::Header] metadata
    # @param [String] payload
    def self.parse(metadata, payload)
      if (message_type = registry[metadata.type])
        message_type.parse(metadata, payload)
      else
        Message.new
      end
    end

    included do
      const_set(:Message, Synapses::Messages::Message)
    end
  end
end

require 'synapses/messages/message'
require 'synapses/messages/coders'

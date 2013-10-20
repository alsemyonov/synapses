# coding: utf-8

################################################
# © Alexander Semyonov, 2013—2013              #
# Author: Alexander Semyonov <al@semyonov.us>  #
################################################

require 'synapses'
require 'synapses/contract/definitions'
require 'synapses/producer/routable'

module Synapses
  # @author Alexander Semyonov <al@semyonov.us>
  class Producer
    include Contract::Definitions
    include Producer::Routable
    include Synapses::Logging

    # @param [AMQP::Channel] channel
    def initialize(channel = AMQP.channel)
      @channel = channel
    end

    # @param [String, Synapses::Messages::Message] message
    # @param [Hash] metadata
    def publish(message, metadata = {}, &block)
      metadata = message.metadata.merge(metadata) if message.respond_to?(:metadata)
      logger.debug(to_s) { "scheduling publishing of #{message} with metadata: #{metadata.inspect}" }
      EM.schedule do
        exchange.publish(message, metadata) do
          logger.debug(to_s) { "published #{message}, #{metadata}]" }
          block.call if block_given?
        end
      end
    rescue => e
      logger.log_exception(e)
    end

    alias << publish
  end
end

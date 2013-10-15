# coding: utf-8

################################################
# © Alexander Semyonov, 2013—2013              #
# Author: Alexander Semyonov <al@semyonov.us>  #
################################################

require 'synapses'
require 'synapses/contract/definitions'

module Synapses
  # @author Alexander Semyonov <al@semyonov.us>
  class Consumer
    include Contract::Definitions
    include Synapses::Logging

    # @return [String]
    class_attribute :queue_name

    # @return [Synapses::Contract]
    class_attribute :contract

    # @return [Array]
    class_attribute :subscriptions
    self.subscriptions = Hash.new { |hash, message_type| hash[message_type] = [] }

    def self.inherited(child)
      super
      child.subscriptions = subscriptions.dup
    end

    # @param [String] name
    # @param [Synapses::Contract] contract
    def self.queue(name, contract = Synapses.default_contract)
      self.queue_name = name
      self.contract = contract
    end

    def self.on(message_type = nil, &block)
      if message_type
        subscriptions[message_type.message_type] << [message_type, block]
      else
        subscriptions[nil] << [nil, block]
      end
    end

    # @param [Hash] options
    # @option options [AMQP::Channel] :channel
    def initialize(options = {})
      @channel = options.fetch(:channel) { Synapses.channel }
      @queue = options.fetch(:queue) { nil }

      subscription_options = options.except(:channel, :queue)

      queue.subscribe(subscription_options, &method(:message_handler))
    end

    # @param [AMQP::Header] metadata
    def message_handler(metadata, payload)
      if (typed_subscriptions = self.subscriptions[metadata.type]).any?
        typed_subscriptions.each do |message_class, block|
          message = message_class.parse(metadata, payload)
          instance_exec(message, &block)
        end
      end

      if (typeless_subscriptions = self.subscriptions[nil]).any?
        typeless_subscriptions.each do |_, block|
          if block.arity == 2
            instance_exec(metadata, payload, &block)
          else
            message = Messages.parse(metadata, payload)
            instance_exec(message, &block)
          end
        end
      end

      unless (typed_subscriptions + typeless_subscriptions).any?
        #puts "  metadata.priority    : #{metadata.priority}"
        #puts "  metadata.headers     : #{metadata.headers.inspect}"
        #puts "  metadata.timestamp   : #{metadata.timestamp.inspect}"
        #puts "  metadata.delivery_tag: #{metadata.delivery_tag}"
        #puts "  metadata.redelivered : #{metadata.redelivered}"
        #puts "  metadata.exchange    : #{metadata.exchange}"
        logger.debug("Message was not processed: [#{metadata.type}] #{payload}, #{metadata.inspect}")
      end
    rescue => e
      logger.log_exception(e)
    end

    # @return [AMQP::Channel]
    attr_accessor :channel

    def queue
      @queue ||= contract.queue(queue_name, channel)
    end
  end
end

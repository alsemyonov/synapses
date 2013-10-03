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
    def self.queue(name, contract=Synapses.default_contract)
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

    # @param [AMQP::Channel] channel
    def initialize(channel = Synapses.default_channel)
      @channel = channel

      queue.subscribe(&method(:message_handler))
    end

    # @param [AMQP::Header] metadata
    def message_handler(metadata, payload)
      if (typed_subscriptions = self.subscriptions[metadata.type]).any?
        typed_subscriptions.each do |message_class, block|
          message = message_class.parse(metadata, payload)
          block.call(message)
        end
      end

      if (typeless_subscriptions = self.subscriptions[nil]).any?
        typeless_subscriptions.each do |_, block|
          if block.arity == 2
            block.call(metadata, payload)
          else
            message = Messages.parse(metadata, payload)
            block.call(message)
          end
        end
      end

      #unless (typed_subscriptions + typeless_subscriptions).any?
      #  puts "#{self} received: #{metadata.type}, #{payload}"
      #  #puts "#{self} received a message:"
      #  #puts "  metadata.routing_key : #{metadata.routing_key}"
      #  #puts "  metadata.content_type: #{metadata.content_type}"
      #  #puts "  metadata.priority    : #{metadata.priority}"
      #  #puts "  metadata.headers     : #{metadata.headers.inspect}"
      #  #puts "  metadata.timestamp   : #{metadata.timestamp.inspect}"
      #  #puts "  metadata.type        : #{metadata.type}"
      #  #puts "  metadata.delivery_tag: #{metadata.delivery_tag}"
      #  #puts "  metadata.redelivered : #{metadata.redelivered}"
      #  ##puts "  metadata.app_id      : #{metadata.app_id}"
      #  #puts "  metadata.exchange    : #{metadata.exchange}"
      #  #puts
      #  #puts "  Received a message: #{payload}"
      #end
    rescue => e
      puts e
    end

    # @return [AMQP::Channel]
    attr_accessor :channel

    def queue
      @queue ||= begin
        queue = contract.queue(queue_name, channel)
        #queue.bind(exchange)
        queue
      end
    end
  end
end

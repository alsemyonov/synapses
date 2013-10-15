# coding: utf-8

require 'synapses/patterns'
require 'synapses/logging'
require 'active_support/core_ext/module/delegation'

module Synapses
  module Patterns
    # Request/Reply is a simple way of integration when one application
    # issues a request and another application responds to it.
    # This pattern is often referred to as "Remote Procedure Call",
    # even when it is not entirely correct.
    # The Request/Reply pattern is a 1:1 communication pattern.
    #
    # Some examples of the Request/Reply pattern are:
    #
    #  * Application 1 requests a document that the Application 2
    #     generates or loads and returns.
    #  * An end-user application issues a search request and
    #     another application returns the results.
    #  * One application requests a progress report from another application.
    module RequestReply
      class Requester
        include Synapses::Producer::Routable
        include Synapses::Logging

        class_attribute :exchange

        def self.next_message_id
          @next_message_id ||= 0
          "#{name}/Message/#{@next_message_id += 1}"
        end

        def self.producer_class
          @producer_class ||= begin
            producer_class = Class.new(Synapses::Producer)
            producer_class.exchange(exchange)
            const_set(:Producer, producer_class)
            const_get(:Producer)
          end
        end

        def self.consumer_class
          @consumer_class ||= begin
            consumer_class = Class.new(Synapses::Consumer)
            const_set(:Consumer, consumer_class)
            const_get(:Consumer)
          end
        end

        def self.on_reply(*args, &block)
          consumer_class.on(*args, &block)
        end

        def initialize(options = {})
          logger.debug("Initializing #{self}")
          @channel = options.fetch(:channel) { Synapses.channel }
          EM.schedule do
            producer
            @reply_queue = options.fetch(:reply_queue) do
              channel.queue('', exclusive: true, auto_delete: true) do |queue, declare_ok|
                logger.debug(declare_ok)
                logger.debug("#{self} declared queue #{queue.name} for replies")
                logger.debug("Binding #{@reply_queue.name} to #{exchange.name}...")
                @reply_queue.bind(exchange, routing_key: @reply_queue.name) do |bind_ok|
                  logger.debug("Just bound #{@reply_queue.name} to #{exchange.name}")
                  logger.debug(bind_ok.inspect)
                end
                consumer.delegate_all_to(self)
              end
            end
          end
        end

        # @return [AMQP::Channel]
        attr_reader :channel

        # @return [AMQP::Exchange]
        def exchange
          producer.exchange
        end

        # @return [AMQP::Queue]
        attr_reader :reply_queue

        def publish(message, options = {}, &block)
          EM.schedule do
            reply_queue.once_declared do
              options[:message_id] ||= self.class.next_message_id
              options[:reply_to] = reply_queue.name
              producer.publish(message, options, &block)
            end
          end
        end

        alias << publish

        def class_name
          self.class.name
        end

        private

        # @return [Synapses::Producer]
        def producer
          @producer ||= self.class.producer_class.new(channel: channel)
        end

        # @return [Synapses::Consumer]
        def consumer
          @consumer ||= self.class.consumer_class.new(channel: channel, queue: @reply_queue)
        end
      end

      class Replier
        include Synapses::Producer::Routable
        include Synapses::Logging

        class_attribute :exchange
        class_attribute :queue
        self.queue = ''

        def self.producer_class
          @producer_class ||= begin
            producer_class = Class.new(Synapses::Producer)
            producer_class.exchange(exchange)
            const_set(:Producer, producer_class)
            const_get(:Producer)
          end
        end

        def self.consumer_class
          @consumer_class ||= begin
            consumer_class = Class.new(Synapses::Consumer)
            consumer_class.queue(queue)
            const_set(:Consumer, consumer_class)
            const_get(:Consumer)
          end
        end

        def self.on(*args, &block)
          consumer_class.on(*args, &block)
        end

        def initialize(options = {})
          logger.debug("Initializing #{self}")
          @channel = options.fetch(:channel) { Synapses.channel }
          consumer.delegate_all_to(self)
          producer
        end

        def class_name
          self.class.name
        end

        # @return [AMQP::Channel]
        attr_reader :channel

        protected

        # @param [Synapses::Messages::Message] request
        # @param [Synapses::Messages::Message] reply
        def reply_to(request, reply)
          producer[request.reply_to].publish(reply, correlation_id: request.message_id, mandatory: true)
          request.ack
        rescue => e
          logger.log_exception(e)
        end

        private

        # @return [Synapses::Producer]
        def producer
          @producer ||= self.class.producer_class.new(channel)
        end

        # @return [Synapses::Consumer]
        def consumer
          @consumer ||= self.class.consumer_class.new(channel: channel, ack: true)
        end
      end
    end
  end
end

require 'synapses/messages'
require 'synapses/messages/coders'
require 'active_support/core_ext/module/delegation'

module Synapses
  module Messages
    # @author Alexander Semyonov <al@semyonov.us>
    class Message
      # @return [String] (nil)
      class_attribute :routing_key

      class << self
        attr_reader :message_type
      end

      def self.message_type=(type)
        Messages.registry[type] = self
        @message_type = type
      end

      # @return [Boolean] (false)
      class_attribute :mandatory
      self.mandatory = false

      # @return [Boolean] (false)
      class_attribute :immediate
      self.immediate = false

      # @return [Boolean] (false)
      class_attribute :persistent
      self.persistent = false

      # @return [String]
      class_attribute :content_type
      #self.content_type = 'application/octet-stream'
      self.content_type = 'application/json'

      class_attribute :attributes
      self.attributes = {}

      def self.inherited(child)
        super
        child.attributes = attributes.dup
      end

      def self.attribute(attr, options = {})
        self.attributes[attr.to_s] = options # TODO add types
        attr_accessor attr
      end

      # @param [String, Hash] attributes_or_payload
      # @param [Hash, AMQP::Header] metadata
      def initialize(attributes_or_payload = {}, metadata = {})
        self.metadata = metadata

        if attributes_or_payload.is_a?(Hash)
          self.attributes = attributes_or_payload
        else
          self.raw_payload = attributes_or_payload
        end
      end

      # @return [String]
      attr_reader :raw_payload

      def raw_payload=(payload)
        @raw_payload = payload
        if content_type? && @raw_payload
          self.attributes = Synapses::Messages::Coders.decode(@raw_payload, content_type)
        end
      end

      # @return [Hash]
      def attributes
        self.class.attributes.inject({}) do |attributes, (name, type)|
          attributes[name] = public_send(name)
          attributes
        end.merge(@attributes)
      end
      alias to_hash attributes

      # @param [Hash] attributes
      def attributes=(attributes)
        @attributes = {}
        assign_attributes(attributes)
      end

      # @param [Hash] attributes
      def assign_attributes(attributes)
        attributes.each do |name, value|
          if respond_to?((writer = "#{name}="))
            send(writer, value)
          else
            @attributes[name] = value
          end
        end
      end

      # @return [String]
      def to_payload
        Synapses::Messages::Coders.encode(attributes, content_type).to_s
      end

      alias to_s to_payload

      def message_type
        @message_type || self.class.message_type
      end

      attr_writer :message_type

      alias type message_type
      alias type= message_type=

      # @return [AMQP::Header]
      attr_reader :header

      delegate :reply_to, :message_id, :correlation_id,
        :ack, :reject, to: :header, allow_nil: true

      def metadata
        {
          routing_key: routing_key,
          type: message_type,
          mandatory: mandatory,
          immediate: immediate,
          persistent: persistent,
          content_type: content_type
        }.merge(@metadata)
      end

      def metadata=(metadata)
        if metadata.is_a?(AMQP::Header)
          @header = metadata
          @metadata = metadata.to_hash
          metadata = @metadata
        else
          @metadata = metadata
        end

        [:routing_key, :message_type, :mandatory, :immediate, :persistent, :content_type].each do |attribute|
          self.public_send("#{attribute}=", metadata[attribute]) if metadata.key?(attribute)
        end
        self.message_type = metadata[:type] if metadata[:type]
      end
    end
  end
end

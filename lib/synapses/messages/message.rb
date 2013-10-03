require 'synapses/messages'
require 'synapses/messages/coders'

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

      def self.parse(metadata, payload)
        new(Synapses::Messages::Coders.decode(payload, metadata.content_type).merge(metadata: metadata))
      end

      def initialize(attributes = {}, metadata = {})
        @attributes = {}
        attributes.each do |name, value|
          if respond_to?((writer = "#{name}="))
            send(writer, value)
          else
            @attributes[name] = value
          end
        end
        metadata.assert_valid_keys(:routing_key, :type)
      end

      attr_accessor :metadata

      def attributes
        self.class.attributes.inject({}) do |attributes, (name, type)|
          attributes[name] = public_send(name)
          attributes
        end.merge(@attributes)
      end

      def to_payload
        Synapses::Messages::Coders.encode(attributes, content_type)
      end

      def message_type
        @message_type || self.class.message_type
      end
      attr_writer :message_type

      alias type message_type
      alias type= message_type=

      def options
        {
          routing_key: routing_key,
          type: message_type,
          mandatory: mandatory,
          immediate: immediate,
          persistent: persistent,
          content_type: content_type
        }
      end
    end
  end
end
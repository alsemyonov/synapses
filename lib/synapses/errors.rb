# coding: utf-8

require 'synapses'

module Synapses
  class Error < StandardError
  end

  class DeclareError < Error
  end

  class MQError < Error
  end

  class ConnectionError < MQError
    def initialize(channel_close)
      super(channel_close.reply_text)
    end
  end

  class ChannelError < MQError
    def initialize(channel_close)
      super(channel_close.reply_text)
    end
  end

  class UnknownError < Error
    def initialize(unknown_name, known_names)
      super("Unknown #{entity}: #{unknown_name}. Known ones are: #{known_names.join(', ')}")
    end

    private

    def self.entity
      @entity ||= begin
        match = self.name.demodulize.match(/^Unknown([\w]+)Error$/)
        match[1]
      end
    end

    def entity
      self.class.entity
    end
  end

  class UnknownExchangeError < UnknownError
  end

  class UnknownQueueError < UnknownError
  end

  class UnknownNamespaceError < UnknownError
  end

  class UnknownMessageError < UnknownError
  end
end

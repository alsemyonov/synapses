# coding: utf-8

################################################
# © Alexander Semyonov, 2013—2013              #
# Author: Alexander Semyonov <al@semyonov.us>  #
################################################

require 'synapses'
require 'synapses/contract/definitions'

module Synapses
  # @author Alexander Semyonov <al@semyonov.us>
  class Producer
    include Contract::Definitions

    def initialize(channel = AMQP.channel)
      @channel = channel
    end

    def <<(message)
      puts #"publishing #{message.to_payload}, #{message.options}"
      EM.next_tick do
        exchange.publish(message.to_payload, message.options) do
          #puts "published [#{message.to_payload}, #{message.options}]"
        end
      end
    end
  end
end
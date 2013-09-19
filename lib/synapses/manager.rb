require 'synapses'
require 'amqp/utilities/event_loop_helper'
require 'amqp/integration/rails'

module Synapses
  # @author Alexander Semyonov <al@semyonov.us>
  class Manager
    def start
      AMQP::Utilities::EventLoopHelper.run
      AMQP::Integration::Rails.start do |connection|
        Synapses.default_connection ||= connection

        connection.on_error do |ch, connection_close|
          raise connection_close.reply_text
        end

        connection.on_tcp_connection_loss do |conn, settings|
          conn.reconnect(false, 2)
        end

        connection.on_tcp_connection_failure do |conn, settings|
          conn.reconnect(false, 2)
        end

        AMQP.channel = channel(connection)
      end
    end

    def channel(connection = Synapses.default_connection)
      channel = AMQP::Channel.new(connection, AMQP::Channel.next_channel_id, auto_recovery: true)
      channel.on_error do |ch, channel_close|
        raise channel_close.reply_text
      end
      channel
    end
  end
end

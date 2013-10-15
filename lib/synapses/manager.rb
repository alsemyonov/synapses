require 'synapses'
require 'amqp/utilities/event_loop_helper'
require 'yaml'
require 'active_support/core_ext/hash/keys'

module Synapses
  # @author Alexander Semyonov <al@semyonov.us>
  class Manager
    # @return [String] application environment
    def self.environment
      if defined?(::Rails)
        ::Rails.env
      else
        ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development'
      end.to_s
    end

    # @return [String] application root directory
    def self.root
      defined?(::Rails) && ::Rails.root || Dir.pwd
    end

    def self.start(options_or_uri = {}, &block)
      yaml     = YAML.load_file(File.join(root, 'config', 'amqp.yml'))
      settings = yaml.fetch(environment, Hash.new).symbolize_keys

      arg      = if options_or_uri.is_a?(Hash)
                   settings.merge(options_or_uri)[:uri]
                 else
                   settings[:uri] || options_or_uri
                 end

      EM.schedule do
        AMQP.logging = true
        AMQP.start(arg, &block)
      end
    end

    def start
      return if @started
      AMQP::Utilities::EventLoopHelper.run
      self.class.start do |connection|
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
        @started = true
        connection
      end
    end

    def channel(connection = Synapses.connection)
      start
      channel = AMQP::Channel.new(connection, AMQP::Channel.next_channel_id, auto_recovery: true)
      channel.on_error do |ch, channel_close|
        raise channel_close.reply_text
      end
    end
  end
end

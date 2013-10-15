# coding: utf-8

################################################
# © Alexander Semyonov, 2013—2013              #
# Author: Alexander Semyonov <al@semyonov.us>  #
################################################

require 'synapses/version'
require 'active_support'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/object/try'
require 'amqp'

# @author Alexander Semyonov <al@semyonov.us>
module Synapses
  def self.manager
    @manager ||= Manager.new
  end

  # @return [Synapses::Contract]
  def self.default_contract
    @default_contract ||= Contract.load_defaults
  end

  def self.channel
    @default_channel ||= connection && AMQP.channel
  end

  def self.connection
    manager.start
    AMQP.connection
  end

  # @return [AMQP::Channel]
  def self.another_channel(connection = Synapses.connection)
    manager.channel(connection)
  end

  def self.setup
    manager.start
    connection
    channel
    true
  rescue => e
    STDERR.puts e.message, e.backtrace
    false
  end

  QUIT_SIGNALS = %w(INT TERM QUIT)

  def self.run
    @running = true
    QUIT_SIGNALS.each do |signal|
      Signal.trap(signal) { Synapses.exit }
    end

    if EM.reactor_running?
      while @running
        #sleep(0.25)
      end
    else
      EM.run
    end
  end

  def self.exit
    @running = false
    Synapses.connection.close { EM.stop }
    exit
  end
end

require 'synapses/logging'
require 'synapses/errors'
require 'synapses/contract'
require 'synapses/contracts'
require 'synapses/producer'
require 'synapses/consumer'
require 'synapses/messages'
require 'synapses/manager'

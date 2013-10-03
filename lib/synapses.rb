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

  def self.default_contract
    @default_contract ||= Contract.load_defaults
  end

  def self.default_channel
    @default_channel ||= default_connection && AMQP.channel
  end

  def self.default_connection
    manager.start
    AMQP.connection
  end


# @return [AMQP::Channel]
  def self.another_channel(connection = Synapses.default_connection)
    manager.channel(connection)
  end

  def self.setup
    manager.start
    default_connection
    default_channel
    true
  rescue => e
    STDERR.puts e.message, e.backtrace
    false
  end

end

require 'synapses/contract'
require 'synapses/producer'
require 'synapses/consumer'
require 'synapses/messages'
require 'synapses/manager'

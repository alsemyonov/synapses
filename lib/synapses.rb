# coding: utf-8

################################################
# © Alexander Semyonov, 2013—2013              #
# Author: Alexander Semyonov <al@semyonov.us>  #
################################################

require 'synapses/version'
require 'active_support'
require 'active_support/core_ext/class/attribute'
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
    @default_connection || manager.start && @default_connection
  end

  def self.default_connection=(connection)
    @default_connection = connection
  end

  def self.another_channel(connection = Synapses.default_connection)
    manager.channel(connection)
  end

  def self.setup
    default_contract
    manager.start
    default_connection
    default_channel
    sleep(0.25)
    #default_contract.setup!
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

# coding: utf-8

require 'synapses/examples'

if ENV['DEBUG'] || ENV['VERBOSE']
  AMQP.logging = true
  Synapses.logger.level = Logger::DEBUG
end

Synapses::Examples.setup

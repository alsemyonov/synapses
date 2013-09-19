# coding: utf-8

################################################
# © Alexander Semyonov, 2013—2013              #
# Author: Alexander Semyonov <al@semyonov.us>  #
################################################

require 'synapses'
require 'yaml'

module Synapses
  # @author Alexander Semyonov <al@semyonov.us>
  class Contract
    # @return [String]
    def self.default_contract_path
      File.expand_path('../contract/synapses.yml', __FILE__)
    end

    # @param [String] file_name
    # @return [Synapse::Contract]
    def self.load_file(file_name)
      hash = YAML.load_file(file_name)
      new(hash)
    end

    # @param [String] root root directory
    def self.load_defaults(root = './')
      contract = new(YAML.load_file(default_contract_path), root: root)

      ([File.join(root, 'config/synapses.yml')] +
        Dir[File.join(root, 'config/synapses/*.yml')]).each do |file_name|

        if File.exists?(file_name)
          hash = YAML.load_file(file_name)
          contract.add_contract(hash)
        end
      end
      contract
    end

    # @param [Hash] hash
    def initialize(hash, options = {})
      @exchanges = Hash.new do |hash, name|
        raise "Unknown Exchange #{name.inspect}. Known are: #{hash.keys.inspect}"
      end
      @queues = Hash.new do |hash, name|
        raise "Unknown Queue #{name.inspect}. Known are: #{hash.keys.inspect}"
      end
      @options = options
      add_contract(hash)
    end

    # @param [Hash] contract_hash
    def add_contract(contract_hash)
      contract_hash.each do |ns, hash|
        ns = hash['ns'] if hash.key?('ns')

        name = hash.delete('name')
        prefix = [ns, name].compact.join('.')

        if hash['exchanges']
          hash.delete('exchanges').each do |name, attributes|
            name = [prefix, name].join('.').to_s
            exchanges[name] = Exchange.new(name, attributes || {})
          end
        end

        if hash['queues']
          hash.delete('queues').each do |name, attributes|
            name = [prefix, name].join('.').to_s
            queues[name.to_s] = Queue.new(name, attributes || {})
          end
        end
      end
    end

    # @param [AMQP::Channel] channel
    def setup!(channel = Synapses.default_channel)
      exchanges.values.each { |exchange| exchange.exchange(channel) }
      queues.values.each { |queue| queue.queue(channel) }
    end

    # @param [Synapses::Contract::Exchange] name
    def exchange_definition(name)
      exchanges[name.to_s]
    end

    # @param [Synapses::Contract::Queue] name
    def queue_definition(name)
      queues[name.to_s]
    end

    # @param [String] name
    # @return [AMQP::Exchange]
    def exchange(name, channel=Synapses.default_channel)
      exchange_definition(name).exchange(channel)
    end

    # @param [String] name
    # @param [AMQP::Channel] channel
    # @return [AMQP::Queue]
    def queue(name, channel=Synapses.default_channel)
      queue_definition(name).queue(channel)
    end

    # @return [Hash]
    attr_reader :exchanges
    # @return [Hash]
    attr_reader :queues
  end
end

require 'synapses/contract/exchange'
require 'synapses/contract/queue'

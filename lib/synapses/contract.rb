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
      @namespaces = Hash.new do |hash, name|
        raise "Unknown Namespace #{name.inspect}. Known are: #{hash.keys.inspect}"
      end
      @messages = Hash.new do |hash, name|
        raise "Unknown Message type #{name.inspect}. Known are: #{hash.keys.inspect}"
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

        namespaces[prefix] = {exchanges: [], queues: [], messages: []} unless namespaces.key?(prefix)

        extract_collection(prefix, :exchanges, hash)
        extract_collection(prefix, :queues, hash)
        extract_collection(prefix, :messages, hash)
      end
    end

    alias << add_contract

    def setup!
      EM.next_tick do
        #setup_channel = Synapses.another_channel
        #setup_channel = Synapses.default_channel
        sleep(0.01) until AMQP.channel.try(:connection).try(:connected?)
        setup_channel = AMQP.channel
        cache = {
          exchanges: {},
          queues: {}
        }
        exchanges.values.each do |exchange|
          next if exchange.system?
          puts "Setting up exchange: #{exchange.inspect}"
          cache[:exchanges][exchange.name] ||= AMQP::Exchange.new(setup_channel, exchange.type, exchange.name, exchange.options)
          puts cache[:exchanges][exchange.name]
        end
        queues.values.each do |queue|
          next if queue.system?
          puts "Setting up queue: #{queue.inspect}"
          cache[:exchanges][queue.name] ||= AMQP::Queue.new(setup_channel, queue.name, queue.options)
          puts cache[:exchanges][queue.name]
          queue.bindings.each do |binding, options|
            puts "Binding queue #{queue.name} to #{binding}, #{options} (#{cache[:exchanges][binding]})"
            cache[:exchanges][queue.name].bind(cache[:exchanges][binding], options)
            #puts cache[:exchanges][queue.name].inspect
          end
        end
        #setup_channel.close
      end
    end

    def generate!
      generator = Generator.new(self)
      generator.write!
    end

    def load!
      namespaces.each do |namespace, _|
        require "synapses/contracts/#{namespace}" unless namespace == 'amq'
      end
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
      exchange = exchanges[name.to_s]
      AMQP::Exchange.new(channel, exchange.type, exchange.name, exchange.options.merge(passive: true))
    end

    # @param [String] name
    # @param [AMQP::Channel] channel
    # @return [AMQP::Queue]
    def queue(name, channel=Synapses.default_channel)
      queue = queues[name.to_s]
      AMQP::Queue.new(channel, queue.name, queue.options.merge(passive: true))
    end

    # @return [Hash]
    attr_reader :exchanges
    # @return [Hash]
    attr_reader :queues
    # @return [Hash]
    attr_reader :namespaces
    # @return [Hash]
    attr_reader :messages

    protected

    # @param [String] namespace
    # @param [Symbol] type
    # @param [Hash] hash
    def extract_collection(namespace, type, hash)
      collection = hash.delete(type.to_s) { {} }
      collection.each do |name, attributes|
        attributes ||= {}
        name = attributes.delete('name') { [namespace, name].join('.').to_s }
        attributes['namespace'] = namespace
        public_send(type)[name] = MAPPINGS[type].new(name, attributes)
        namespaces[namespace][type] << name
      end
    end

    require 'synapses/contract/exchange'
    require 'synapses/contract/queue'
    require 'synapses/contract/message_type'
    require 'synapses/contract/generator'

    MAPPINGS = {
      exchanges: Exchange,
      queues: Queue,
      messages: MessageType
    }
  end
end

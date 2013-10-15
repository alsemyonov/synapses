# coding: utf-8

require 'synapses'

module Synapses
  module Examples
    def self.setup
      Synapses.default_contract.load_file File.expand_path('../examples/contract.yml', __FILE__)
      Synapses::Contracts.load
    end
  end
end

require 'synapses'
require 'synapses/logging'

module Synapses
  module Contracts
    include Synapses::Logging

    def self.load
      Synapses.setup
      contract = Synapses.default_contract
      contract.generate!
      contract.setup!
      contract.load!
      sleep(0.25)
    end
  end
end

require 'synapses'

module Synapses
  module Contracts
    def self.load
      Synapses.setup
      contract = Synapses.default_contract
      contract.generate!
      contract.setup!
      contract.load!
    end
  end
end

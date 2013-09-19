require 'synapses/contract'
require 'active_support/concern'

module Synapses
  class Contract
    # @author Alexander Semyonov <al@semyonov.us>
    module Definitions
      extend ActiveSupport::Concern

      included do
        # @return [String]
        class_attribute :exchange_name
        self.exchange_name = ''

        # @return [Synapses::Contract]
        class_attribute :contract
      end

      module ClassMethods
        # @param [String] name
        # @param [Synapses::Contract] contract
        def exchange(name, contract=Synapses.default_contract)
          self.exchange_name = name
          self.contract = contract
        end
      end

      # @return [AMQP::Exchange]
      def exchange
        @exchange ||= contract.exchange(exchange_name)
      end
    end
  end
end

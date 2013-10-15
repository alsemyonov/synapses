# coding: utf-8
require 'synapses'
require 'synapses/messages'
require 'synapses/contracts/autogen/synapses.examples.get_time'

module Synapses
  module Contracts
    module Synapses
      module Examples
        module GetTime
          module Messages
            include ::Synapses::Messages
          
            
            class Procedure < Message
            end
          
            
            class ProcedureResult < Message
            end
          
            
          end
        end
      end
    end
  end
end

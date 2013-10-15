# coding: utf-8
require 'synapses'
require 'synapses/messages'
require 'synapses/contracts/autogen/synapses.examples.rockets.gov.radar'

module Synapses
  module Contracts
    module Synapses
      module Examples
        module Rockets
          module Gov
            module Radar
              module Messages
                include ::Synapses::Messages

                class UFO < Message
                  def description
                    "UFO in shape of #{shape}, colored in #{color}"
                  end
                end

                class Rocket < Message
                  def description
                    "There is a rocket flying to the #{target} (#{speed})!"
                  end
                end

                class Plane < Message
                  def description
                    "There is a #{brand} Plane!"
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end

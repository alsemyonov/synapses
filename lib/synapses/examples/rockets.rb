#!/usr/bin/env ruby

require 'synapses/examples/setup'

module Synapses
  module Examples
    module Rockets
      module Messages
        include Synapses::Contracts::Synapses::Examples::Rockets::Gov::Radar::Messages
        include Synapses::Contracts::Synapses::Examples::Rockets::Mil::RocketCenter::Messages
      end

      class Radar < Synapses::Producer
        exchange 'synapses.examples.rockets.gov.radar.announce'
      end

      class RocketCenter < Synapses::Producer
        exchange 'synapses.examples.rockets.mil.rocket_center.commander'
      end

      class RocketLauncher < Synapses::Consumer
        queue 'synapses.examples.rockets.mil.rocket_center.rocket_launcher'

        on(Messages::UFO) { |msg| logger.info('RocketLauncher') { msg.description } }
        on(Messages::Rocket) { |msg| logger.info('RocketLauncher') { msg.description } }
      end

      class RocketShield < Synapses::Consumer
        queue 'synapses.examples.rockets.mil.rocket_center.rocket_shield'

        on(Messages::Protect) { |msg| logger.info('RocketShield') { "Protect -> #{msg}" } }
      end

      class RadarLogger < Synapses::Consumer
        exchange 'amq.fanout'
        queue 'synapses.examples.rockets.gov.radar.logger'

        on { |metadata, payload| logger.info('RadarLogger') { "#{metadata.type}, #{payload}" } }
      end
    end
  end
end

if $0 == __FILE__
  include Synapses::Examples::Rockets

  Synapses.setup

  rockets_center_channel = Synapses.another_channel
  rocket_launcher = RocketLauncher.new(channel: rockets_center_channel)
  rocket_shield = RocketShield.new(channel: rockets_center_channel)

  logger_channel = AMQP.channel
  radar_logger = RadarLogger.new(channel: logger_channel)

  radar_channel = Synapses.another_channel
  radar = Radar.new(radar_channel)

  puts 'Publishing Radar messages'
  1000.times do |i|
    radar << Messages::Plane.new(brand: 'boeing') if (i % 3) == 0
    radar << Messages::Rocket.new(target: 'Moon', speed: 42 * i) if (i % 4) == 0
    radar << Messages::UFO.new(shape: 'circle', color: 'green') if (i % 5) == 0
  end

  Synapses.run
end

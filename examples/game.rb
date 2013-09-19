#!/usr/bin/env ruby

$:.unshift File.expand_path('../../lib', __FILE__)
require 'synapses'

Synapses.setup

module Messages
  include Synapses::Messages

  class UFO < Message
    self.routing_key = 'gov.radar.ufo'
    self.message_type = 'gov.radar.ufo'
    attribute :shape
    attribute :color

    def description
      "UFO in shape of #{shape}, colored in #{color}"
    end
  end

  class Plane < Message
    self.routing_key = 'gov.radar.plane'
    self.message_type = 'gov.radar.plane'
    attribute :brand

    def description
      "There is a #{brand} Plane!"
    end
  end

  class Rocket < Message
    self.routing_key = 'gov.radar.rocket'
    self.message_type = 'gov.radar.rocket'
    attribute :speed
    attribute :target

    def description
      "There is a rocket flying to the #{target} (#{speed})!"
    end
  end

  class Protect < Message
    self.routing_key = 'mil.rocket_center.protect'
    self.message_type = 'mil.rocket_center.protect'
  end
end

class Radar < Synapses::Producer
  exchange 'amq.fanout'
end

class RocketCenter < Synapses::Producer
  exchange 'amq.direct'
end

class RocketLauncher < Synapses::Consumer
  exchange 'amq.fanout'
  queue 'mil.rocket_center.rocket_launcher'

  on Messages::UFO do |ufo|
    puts "RocketLauncher: Messages::UFO -> #{ufo.description}"
  end

  on Messages::Rocket do |rocket|
    puts "RocketLauncher: Messages::Rocket -> #{rocket.description}"
  end
end

class RocketShield < Synapses::Consumer
  exchange 'amq.fanout'
  queue 'mil.rocket_center.rocket_shield'

  on Messages::Protect do |protect|
    puts "RocketShield: Messages::Protect -> #{protect}"
  end
end

class RadarLogger < Synapses::Consumer
  exchange 'amq.fanout'
  queue 'gov.radar.logger'

  on do |metadata, payload|
    puts "RadarLogger -> #{metadata.routing_key}, #{payload}"
  end
end

rockets_center_channel = Synapses.another_channel
rocket_launcher = RocketLauncher.new(rockets_center_channel)
rocket_shield = RocketShield.new(rockets_center_channel)

logger_channel = Synapses.another_channel
radar_logger = RadarLogger.new(logger_channel)

radar_channel = Synapses.another_channel
radar = Radar.new(radar_channel)

puts 'Publishing Radar messages'
1000.times do |i|
radar << Messages::Plane.new(brand: 'boeing') if (i % 3) == 0
radar << Messages::Rocket.new(target: 'Moon', speed: 42 * i) if (i % 4) == 0
radar << Messages::UFO.new(shape: 'circle', color: 'green') if (i % 5) == 0
end

EM.run do
  tick_tack = true
  EM.add_periodic_timer(2) { puts (tick_tack = !tick_tack) ? 'tick' : 'tack' }
end

sleep(10)

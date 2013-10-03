#!/usr/bin/env ruby

$:.unshift File.expand_path('../../lib', __FILE__)
$:.unshift File.expand_path('../lib', __FILE__)
Dir.chdir File.expand_path('..', __FILE__)

require 'synapses/contracts'

Synapses::Contracts.load

#EM.run do
#  EM.add_timer(2) { AMQP.connection.close { EM.stop } }
#  EM.add_timer(2) {  EM.stop }
#end

module Messages
  include Synapses::Contracts::Gov::Radar::Messages
  include Synapses::Contracts::Mil::RocketCenter::Messages
end

class Radar < Synapses::Producer
  exchange 'gov.radar.announce'
end

class RocketCenter < Synapses::Producer
  exchange 'mil.rocket_center.commander'
end

class RocketLauncher < Synapses::Consumer
  queue 'mil.rocket_center.rocket_launcher'

  on(Messages::UFO) { |msg| puts "RocketLauncher: #{msg.description}" }
  on(Messages::Rocket) { |msg| puts "RocketLauncher: #{msg.description}" }
end

class RocketShield < Synapses::Consumer
  queue 'mil.rocket_center.rocket_shield'

  on(Messages::Protect) { |msg| puts "RocketShield: Protect -> #{msg}" }
end

class RadarLogger < Synapses::Consumer
  exchange 'amq.fanout'
  queue 'gov.radar.logger'

  on { |metadata, payload| puts "RadarLogger -> #{metadata.type}, #{payload}" }
end

EM.run do

  rockets_center_channel = Synapses.another_channel
  #rockets_center_channel = AMQP.channel
  rocket_launcher = RocketLauncher.new(rockets_center_channel)
  rocket_shield = RocketShield.new(rockets_center_channel)

  #logger_channel = Synapses.another_channel
  logger_channel = AMQP.channel
  radar_logger = RadarLogger.new(logger_channel)

  radar_channel = Synapses.another_channel
  #radar_channel = AMQP.channel
  radar = Radar.new(radar_channel)

  puts 'Publishing Radar messages'
  1000.times do |i|
    radar << Messages::Plane.new(brand: 'boeing') if (i % 3) == 0
    radar << Messages::Rocket.new(target: 'Moon', speed: 42 * i) if (i % 4) == 0
    radar << Messages::UFO.new(shape: 'circle', color: 'green') if (i % 5) == 0
  end

  tick_tack = true
  EM.add_periodic_timer(1) { puts (tick_tack = !tick_tack) ? 'tick' : 'tack' }
  EM.add_timer(10) do
    Synapses.default_connection.close { EM.stop }
  end
end

sleep 10

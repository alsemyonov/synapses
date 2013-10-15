# coding: utf-8
require 'synapses/examples/setup'
require 'synapses/patterns/request_reply'
require 'time'
require 'active_support/core_ext/time/zones'

module Synapses
  module Examples
    module GetTime
      module Messages
        include Synapses::Contracts::Synapses::Examples::GetTime::Messages
      end

      class Client < Synapses::Patterns::RequestReply::Requester
        GET_TIME_SERVICE = 'synapses.examples.get_time.get_time'

        self.exchange = 'synapses.examples.get_time.service'

        def get_local
          logger.info(class_name) { 'Requesting local time...' }
          publish Messages::Procedure.new({procedure: 'get.time.local'}), routing_key: GET_TIME_SERVICE
        end

        def get_utc
          get_time_in('UTC')
        end

        def get_time_in(time_zone)
          logger.info(class_name) { "Requesting time in #{time_zone}..." }
          publish Messages::Procedure.new({procedure: 'get.time.zone', arguments: time_zone}), routing_key: GET_TIME_SERVICE
        end

        on_reply Messages::ProcedureResult do |reply|
          logger.info(class_name) { "Received reply [#{reply.correlation_id}]: #{reply.procedure}, #{reply.result}" }
        end
      end

      class Server < Synapses::Patterns::RequestReply::Replier
        self.exchange = 'synapses.examples.get_time.service'
        self.queue = 'synapses.examples.get_time.get_time'

        on Messages::Procedure do |procedure|
          case procedure.procedure
          when 'get.time.utc'
            logger.info(class_name) { "Request for UTC time [#{procedure.message_id}]" }
            reply_to(procedure, Messages::ProcedureResult.new(procedure: procedure.procedure, result: get_time('UTC').xmlschema))
          when 'get.time.local'
            logger.info(class_name) { "Request for local time [#{procedure.message_id}]" }
            reply_to(procedure, Messages::ProcedureResult.new(procedure: procedure.procedure, result: get_time(nil).xmlschema))
          when 'get.time.zone'
            logger.info(class_name) { "Request for time in TZ #{procedure.arguments.inspect} [#{procedure.message_id}]" }
            reply_to(procedure, Messages::ProcedureResult.new(procedure: procedure.procedure, result: get_time(procedure.arguments).xmlschema))
          else
            logger.warn(class_name) { "Unknown procedure called: #{procedure.message_type}" }
            raise "Unknown procedure called: #{procedure.message_type}"
          end
        end

        protected

        def get_time(time_zone)
          if time_zone
            Time.now.in_time_zone(time_zone)
          else
            Time.now
          end
        end
      end
    end
  end
end

if $0 == __FILE__
  include Synapses::Examples

  server = GetTime::Server.new

  client = GetTime::Client.new
  5.times do
    client.get_local
    client.get_utc
    client.get_time_in('St. Petersburg')
    client.get_time_in('Pacific Time (US & Canada)')
  end
  ActiveSupport::TimeZone.all.each do |time_zone|
    client.get_time_in(time_zone.name)
  end

  Synapses.run
end

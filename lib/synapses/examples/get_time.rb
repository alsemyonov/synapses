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
          logger.info('Requesting local time...')
          publish Messages::Procedure.new({procedure: 'get.time.local'}), routing_key: GET_TIME_SERVICE
        end

        def get_utc
          get_time_in('UTC')
          #logger.info('Requesting UTC time...')
          #publish Messages::Procedure.new({procedure: 'get.time.utc'}), routing_key: GET_TIME_SERVICE
        end

        def get_time_in(time_zone)
          logger.info("Requesting time in #{time_zone}...")
          publish Messages::Procedure.new({procedure: 'get.time.zone', arguments: time_zone}), routing_key: GET_TIME_SERVICE
        end

        on_reply Messages::ProcedureResult do |reply|
          logger.info('Received reply:')
          logger.info("#{reply.procedure}, #{reply.result}")
        end
      end

      class Server < Synapses::Patterns::RequestReply::Replier
        self.exchange = 'synapses.examples.get_time.service'
        self.queue = 'synapses.examples.get_time.get_time'

        on Messages::Procedure do |procedure|
          case procedure.procedure
          when 'get.time.utc'
            logger.info('Request for UTC time')
            reply_to(procedure, Messages::ProcedureResult.new(procedure: procedure.procedure, result: get_time('UTC').xmlschema))
          when 'get.time.local'
            logger.info('Request for local time')
            reply_to(procedure, Messages::ProcedureResult.new(procedure: procedure.procedure, result: get_time(nil).xmlschema))
          when 'get.time.zone'
            logger.info("Request for time in TZ: #{procedure.arguments}")
            reply_to(procedure, Messages::ProcedureResult.new(procedure: procedure.procedure, result: get_time(procedure.arguments).xmlschema))
          else
            logger.warn("Unknown procedure called: #{procedure.message_type}")
            raise "Unknown procedure called: #{procedure.message_type}"
          end
        end

        #on do |metadata, payload|
        #  puts "ONONON"
        #  logger.warn("Received unknown message: #{payload}, #{metadata.type}")
        #end

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
  sleep(1)

  client = GetTime::Client.new
  sleep(1)
  5.times do
    client.get_local
    client.get_utc
    client.get_time_in('St. Petersburg')
    client.get_time_in('Pacific Time (US & Canada)')
  end
#client.get_utc
  sleep(1)

  Synapses.run
end

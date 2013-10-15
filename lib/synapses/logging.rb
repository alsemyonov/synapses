# coding: utf-8

require 'synapses'
require 'logger'
require 'active_support/concern'

module Synapses
  module Logging
    extend ActiveSupport::Concern

    class Logger < ::Logger
      # @param [Exception] exception
      def log_exception(exception)
        error(exception.message)
        debug(exception.backtrace.join("\n"))
      end
    end

    # @return [Logger]
    def self.logger
      @logger ||= begin
        logger = Synapses::Logging::Logger.new(STDOUT)
        logger.level = Logger::INFO
        logger
      end
    end

    def self.logger=(logger)
      @logger = logger
    end

    module ClassMethods
      # @return [Synapses::Logging::Logger]
      def logger
        @logger || Logging.logger
      end
      attr_writer :logger
    end

    # @return [Synapses::Logging::Logger]
    def logger
      @logger || Logging.logger
    end
    attr_writer :logger
  end

  include Logging
end

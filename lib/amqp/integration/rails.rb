require 'yaml'
require 'active_support/core_ext/hash/keys'

module AMQP
  module Integration
    class Rails
      # @return [String] application environment
      def self.environment
        if defined?(::Rails)
          ::Rails.env
        else
          ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development'
        end
      end

      # @return [String] application root directory
      def self.root
        defined?(::Rails) && ::Rails.root || Dir.pwd
      end

      def self.start(options_or_uri = {}, &block)
        yaml     = YAML.load_file(File.join(root, 'config', 'amqp.yml'))
        settings = yaml.fetch(environment, Hash.new).symbolize_keys

        arg      = if options_or_uri.is_a?(Hash)
                     settings.merge(options_or_uri)[:uri]
                   else
                     settings[:uri] || options_or_uri
                   end

        EventMachine.next_tick do
          AMQP.start(arg, &block)
        end
      end
    end # Rails
  end # Integration
end # AMQP

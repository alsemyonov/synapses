require 'synapses/contract'
require 'fileutils'
require 'erb'
require 'active_support/core_ext/string/inflections'

module Synapses
  class Contract
    class Generator
      def initialize(contract)
        @contract = contract
      end

      # @return [Synapses::Contract]
      attr_reader :contract

      def write!
        FileUtils.mkdir_p(contracts_autogen_dir)
        contract.namespaces.each do |namespace, contents|
          next if namespace == 'amq'
          file_name = "#{namespace}.rb"
          contract_file = File.join(contracts_dir, file_name)
          autogen_file = File.join(contracts_autogen_dir, file_name)
          write_template(namespace, :autogen, autogen_file)
          write_template(namespace, :overrides, contract_file) unless File.file?(contract_file)
        end
      end

      protected

      def templates
        @templates ||= Hash.new do |store, template_name|
          store[template_name] = File.read(File.expand_path("../generator/#{template_name}.rb.erb", __FILE__))
        end
      end

      def write_template(namespace, template_name, file_name)
        template = templates[template_name]
        exchanges = contract.namespaces[namespace][:exchanges].map { |name| contract.exchanges[name] }
        queues = contract.namespaces[namespace][:queues].map { |name| contract.queues[name] }
        messages = contract.namespaces[namespace][:messages].map { |name| contract.messages[name] }
        result = ERB.new(template, 0, '%<>').result(binding)
        File.write(file_name, result)
      end

      def module_for_namespace(namespace, &block)
        indent = '  '
        modules = namespace.split(/\./).map { |name| "#{(indent << '  ')}module #{name.underscore.camelcase(:upper)}\n" }
        erbout = block.binding.eval('_erbout')
        modules.each { |mod| erbout << mod }
        block.binding.eval('_erbout, @_old_erbout = "", _erbout')
        yield
        indent << '  '
        block.binding.eval(%[_erbout = _erbout.split("\n").map {|line| "#{indent}\#{line}"}.join("\n"); @_old_erbout << _erbout << "\n"; _erbout = @_old_erbout])
        modules.reverse.each { |mod| erbout << mod.gsub(/module .*$/, 'end') }
      end

      def contracts_autogen_dir
        File.join(contracts_dir, 'autogen')
      end

      def contracts_dir
        @contracts_dir ||= File.join(root_dir, 'lib/synapses/contracts')
      end

      def root_dir
        @root_dir ||= Dir.pwd
      end
    end
  end
end

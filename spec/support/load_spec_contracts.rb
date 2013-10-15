# coding: utf-8

require 'synapses'

contract = Synapses.default_contract
Dir[File.expand_path('../../config/synapses/*.yml', __FILE__)].each do |file_name|
  contract.load_file(file_name)
end

Synapses.setup

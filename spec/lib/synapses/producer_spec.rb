require 'spec_helper'

describe Synapses::Producer do
  context 'class' do
    subject { described_class }

    it { should respond_to(:exchange) }
  end

  context 'instance' do
    subject { described_class.new }

    it { should respond_to(:<<) }
    it { should respond_to(:[]) }
  end
end

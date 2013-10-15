require 'spec_helper'

require 'synapses/examples/get_time'

describe Synapses::Patterns::RequestReply do
end

describe Synapses::Patterns::RequestReply::Requester do
  let(:described_class) { Synapses::Examples::GetTime::Client }

  context 'class' do
    subject { described_class }

    it { should respond_to(:exchange) }
    it { should respond_to(:on_reply) }
  end

  context 'instance' do
    subject { described_class.new }
    it { should respond_to(:<<) }
    it { should respond_to(:[]) }
  end
end

describe Synapses::Patterns::RequestReply::Replier do
  let(:described_class) { Synapses::Examples::GetTime::Server }

  context 'class' do
    subject { described_class }

    it { should respond_to(:exchange) }
    it { should respond_to(:queue) }
  end
end

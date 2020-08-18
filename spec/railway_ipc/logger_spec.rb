# frozen_string_literal: true

require 'spec_helper'

%w[fatal error warn info debug].each do |level|
  RSpec.describe RailwayIpc::Logger, "##{level}" do
    let(:io) { StringIO.new }
    let(:parsed_log_str) { JSON.parse(io.string, symbolize_names: true) }

    subject { described_class.new(io, Logger::DEBUG) }

    context 'when there is a bare message' do
      before(:each) { subject.send(level, 'some message') }

      it { expect(io.string).to include(level.upcase) }
      it { expect(io.string).to include('some message') }
    end

    context 'when extra data is provided' do
      before(:each) { subject.send(level, 'some message', protobuf: stubbed_protobuf) }

      it { expect(io.string).to include(level.upcase) }
      it { expect(io.string).to include('some message') }

      it 'includes the data in the output' do
        expect(io.string).to \
          include('correlation_id: "cafef00d-cafe-cafe-cafe-cafef00dcafe"')
      end
    end
  end
end

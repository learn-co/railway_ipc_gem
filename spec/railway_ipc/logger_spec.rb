# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/BlockLength
%w[fatal error warn info debug].each do |level|
  RSpec.describe RailwayIpc::Logger, "##{level}" do
    let(:io) { StringIO.new }
    let(:parsed_log_str) { JSON.parse(io.string, symbolize_names: true) }

    subject { described_class.new(io, Logger::DEBUG) }

    context 'when there is a bare message' do
      before(:each) { subject.send(level, 'some message') }

      it { expect(io.string).to include(level.upcase) }
      it { expect(io.string).to include(':message=>"some message"') }
      it { expect(io.string).to_not include(':progname') }

      it 'logs a default `feature` key' do
        expect(io.string).to include(':feature=>"railway_ipc"')
      end

      context 'and a block is given' do
        before(:each) { subject.send(level, 'some_message') { 'message in a block' } }

        it { expect(io.string).to include(level.upcase) }
        it { expect(io.string).to include(':message=>"message in a block"') }

        it 'logs a default `feature` key' do
          expect(io.string).to include(':feature=>"railway_ipc"')
        end

        it 'sets the given message as the progname' do
          expect(io.string).to include(':progname=>"some_message"')
        end
      end
    end

    context 'when there is no message' do
      context 'and a block is given' do
        before(:each) { subject.send(level) { 'message in a block' } }

        it { expect(io.string).to include(level.upcase) }
        it { expect(io.string).to include(':message=>"message in a block"') }
        it { expect(io.string).to_not include(':progname') }

        it 'logs a default `feature` key' do
          expect(io.string).to include(':feature=>"railway_ipc"')
        end
      end

      context 'and no block is given' do
        before(:each) { subject.send(level) }

        it { expect(io.string).to include(level.upcase) }
        it { expect(io.string).to include(':message=>nil') }

        it 'does not add a `progname`' do
          expect(io.string).to_not include(':progname')
        end

        it 'logs a default `feature` key' do
          expect(io.string).to include(':feature=>"railway_ipc"')
        end
      end
    end

    context 'when extra data is provided' do
      before(:each) do
        kwargs = { protobuf: stubbed_protobuf, feature: 'example' }
        subject.send(level, 'some message', **kwargs)
      end

      it { expect(io.string).to include(level.upcase) }
      it { expect(io.string).to include(':message=>"some message"') }
      it { expect(io.string).to_not include(':progname') }

      it 'includes the data in the output' do
        expect(io.string).to \
          include('correlation_id: "cafef00d-cafe-cafe-cafe-cafef00dcafe"')
      end

      it 'allows a `feature` key to be set' do
        expect(io.string).to include(':feature=>"example"')
      end

      context 'and the `feature` key is not provided' do
        it 'logs a default `feature` key' do
          subject.send(level, 'some message', protobuf: stubbed_protobuf)
          expect(io.string).to include(':feature=>"railway_ipc"')
        end
      end

      context 'and a block is given' do
        before(:each) do
          kwargs = { protobuf: stubbed_protobuf, feature: 'example' }
          subject.send(level, **kwargs) { 'message in a block' }
        end

        it { expect(io.string).to include(level.upcase) }
        it { expect(io.string).to include(':message=>"message in a block"') }
        it { expect(io.string).to_not include(':progname') }

        it 'includes the data in the output' do
          expect(io.string).to \
            include('correlation_id: "cafef00d-cafe-cafe-cafe-cafef00dcafe"')
        end

        it 'allows a `feature` key to be set' do
          expect(io.string).to include(':feature=>"example"')
        end

        context 'and the `feature` key is not provided' do
          it 'logs a default `feature` key' do
            subject.send(level, protobuf: stubbed_protobuf) { 'message in a block' }
            expect(io.string).to include(':feature=>"railway_ipc"')
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength

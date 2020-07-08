# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RailwayIpc::PublishedMessage, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:uuid) }
    it { should validate_presence_of(:status) }
  end

  describe '#create' do
    it 'saves an inserted_at date for the current time' do
      msg = RailwayIpc::PublishedMessage.create({
                                                  uuid: SecureRandom.uuid,
                                                  message_type: 'loader',
                                                  encoded_message: '1ZX-343',
                                                  status: 'failure'
                                                })

      expect(msg.inserted_at.utc).to be_within(1.second).of(Time.current)
    end
  end
end

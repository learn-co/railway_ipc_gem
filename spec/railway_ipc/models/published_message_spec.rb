require 'rails_helper'

RSpec.describe RailwayIpc::PublishedMessage do
  describe 'on DB creation' do
    it 'saves an inserted_at date for the current time' do
      msg = RailwayIpc::PublishedMessage.create({
        uuid: '123',
        message_type: 'loader',
        encoded_message: '1ZX-343'
      })

      expect(msg.inserted_at).to be_within(1.second).of(Time.current)
    end
  end
end
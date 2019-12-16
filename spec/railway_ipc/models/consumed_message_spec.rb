require 'rails_helper'

 RSpec.describe RailwayIpc::ConsumedMessage do
   describe 'initial save to DB' do
     it 'saves an inserted_at date for the current time' do
       msg = RailwayIpc::ConsumedMessage.create({
         uuid: SecureRandom.uuid,
         message_type: 'loader',
         encoded_message: '1ZX-343',
         status: 'failure'
       })

       expect(msg.inserted_at.utc).to be_within(1.second).of(Time.current)
     end
   end
 end

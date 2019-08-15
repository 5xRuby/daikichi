# frozen_string_literal: true

require 'rails_helper'
RSpec.describe Backend::LeaveTimesController, type: :controller do
  describe 'POST #batch_create' do
    before do
      sign_in create(:manager_eddie)
      5.times { FactoryBot.create(:user) }
    end
    it 'add leave time to each users' do
      expect do
        post :batch_create, params: { leave_time: { 'user_id' => User.select(:id).last(4), 'leave_type' => 'personal', 'quota' => '3', 'effective_date' => '2017/12/15', 'expiration_date' => '2017/12/25', 'remark' => 'fd' } }
      end.to change(LeaveTime, :count).by(4)
    end
  end
end

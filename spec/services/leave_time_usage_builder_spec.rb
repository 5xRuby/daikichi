require 'rails_helper'

describe LeaveTimeUsageBuilder do
  let(:user) { create(:user) }

  describe '.leave_hours_by_date' do
    let(:effective_date)    { Time.zone.local(2017, 5, 1).to_date }
    let(:expiration_date)   { Time.zone.local(2017, 5, 31).to_date }
    let(:start_time)        { Time.zone.local(2017, 5, 4, 9, 30) }
    let(:end_time)          { Time.zone.local(2017, 5, 9, 12, 30) }
    let(:leave_application) { build(:leave_application, :annual, user: user, start_time: start_time, end_time: end_time) }

    before do
      User.skip_callback(:create, :after, :auto_assign_leave_time)
      create(:leave_time, :annual, user: user, quota: 100, usable_hours: 100, effective_date: effective_date, expiration_date: expiration_date)
    end
    after  { User.set_callback(:create, :after, :auto_assign_leave_time)  }

    it 'returns a hash to represent leave time as hours by date' do
      builder = described_class.new leave_application
      
      expect(builder.leave_hours_by_date).to eq ({
        Time.zone.local(2017, 5, 4).to_date => 8,
        Time.zone.local(2017, 5, 5).to_date => 8,
        Time.zone.local(2017, 5, 8).to_date => 8,
        Time.zone.local(2017, 5, 9).to_date => 3
      })
    end
  end

  describe '.build_leave_time_usages' do
  end
end
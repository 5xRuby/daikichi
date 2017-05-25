require 'rails_helper'

describe LeaveTimeUsageBuilder do
  let(:user)              { create(:user) }
  let(:start_time)        { Time.zone.local(2017, 5, 4, 9, 30) }
  let(:end_time)          { Time.zone.local(2017, 5, 9, 12, 30) }
  let(:leave_application) { build(:leave_application, :annual, user: user, start_time: start_time, end_time: end_time) }
  let(:total_used_hours)  { $biz.within(start_time, end_time).in_hours }

  describe '.leave_hours_by_date' do
    let(:effective_date)    { Time.zone.local(2017, 5, 1).to_date }
    let(:expiration_date)   { Time.zone.local(2017, 5, 31).to_date }
    
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
      expect(builder.leave_hours_by_date.values.sum).to eq total_used_hours
    end
  end

  describe '.build_leave_time_usages' do
    context 'LeaveTime covers LeaveApplication time interval' do
      it 'should create successfully with sufficient usable hours' do
      end

      it 'should create failed with insufficient usable hours' do
      end
    end

    context 'multiple LeaveTimes cover LeaveApplication time interval' do
      it 'should create successfully with two LeaveTimes covers LeaveApplication' do
      end

      it 'should create successfully with three LeaveTimes covers LeaveApplication' do
      end

      it 'should create failed with two LeaveTimes covers LeaveApplication with insufficient values' do
      end
    end

    context 'didn\'t completely covered LeaveApplication' do
      it 'create failed with two LeaveTimes not covering the start_time of LeaveApplication' do
      end

      it 'create failed with two LeaveTimes not covering the middle time interval of LeaveApplication' do
      end

      it 'create failed with two LeaveTimes not covering the end_time of LeaveApplication' do
      end  
    end

    context 'lock hours priority' do
      context 'fullpaid sick prior to halfpaid sick' do
      end

      context 'nearly expired LeaveTime prior to other LeaveTimes' do        
      end

      context 'less usable_hours LeaveTime prior to other LeaveTimes' do
      end

      context 'nearly expired LeaveTime is prior to less usable_hours LeaveTimes' do
      end
    end
  end
end
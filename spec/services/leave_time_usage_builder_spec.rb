require 'rails_helper'

describe LeaveTimeUsageBuilder do
  let(:user)              { create(:user) }
  let(:start_time)        { Time.zone.local(2017, 5, 4, 9, 30) }
  let(:end_time)          { Time.zone.local(2017, 5, 9, 12, 30) }
  let(:leave_application) { create(:leave_application, :annual, user: user, start_time: start_time, end_time: end_time) }
  let(:total_used_hours)  { Daikichi::Config::Biz.within(start_time, end_time).in_hours }

  before { User.skip_callback(:create, :after, :auto_assign_leave_time) }
  after  { User.set_callback(:create, :after, :auto_assign_leave_time)  }

  describe '.leave_hours_by_date' do
    let(:effective_date)    { Date.parse('2017-05-01') }
    let(:expiration_date)   { Date.parse('2017-05-31') }

    before { create(:leave_time, :annual, user: user, quota: 100, usable_hours: 100, effective_date: effective_date, expiration_date: expiration_date) }

    it 'returns a hash to represent leave time as hours by date' do
      builder = described_class.new leave_application
      expect(builder.leave_hours_by_date).to eq ({
        Date.parse('2017-05-04') => 8,
        Date.parse('2017-05-05') => 8,
        Date.parse('2017-05-08') => 8,
        Date.parse('2017-05-09') => 3
      })
      expect(builder.leave_hours_by_date.values.sum).to eq total_used_hours
    end
  end

  describe '.build_leave_time_usages' do
    context 'LeaveTime covers LeaveApplication time interval' do
      let(:effective_date)  { Date.parse('2017-05-01') }
      let(:expiration_date) { Date.parse('2017-05-31') }
      let(:quota)           { 50 }
      before { create(:leave_time, :annual, user: user, quota: quota, usable_hours: quota, effective_date: effective_date, expiration_date: expiration_date) }

      it 'should create successfully with sufficient usable hours' do
        leave_application = create(:leave_application, :annual, user: user, start_time: Time.zone.local(2017, 5, 1, 9, 30), end_time: Time.zone.local(2017, 5, 5, 12, 30))
        leave_time_usage = leave_application.leave_time_usages.first
        leave_time = leave_time_usage.leave_time
        expect(leave_application.leave_time_usages.size).to eq 1
        expect(leave_time_usage.used_hours).to eq leave_application.hours
        expect(leave_time.usable_hours).to eq (quota - leave_application.hours)
        expect(leave_time.used_hours).to be_zero
        expect(leave_time.locked_hours).to eq leave_application.hours
      end

      it 'should create failed with insufficient usable hours' do
        leave_application = create(:leave_application, :annual, user: user, start_time: Time.zone.local(2017, 5, 1, 9, 30), end_time: Time.zone.local(2017, 5, 31, 12, 30))
        leave_time = user.leave_times.first
        expect(user.leave_applications).to be_empty
        expect(LeaveTimeUsage.where(leave_application: leave_application)).to be_empty
        expect(leave_time.usable_hours).to eq quota
        expect(leave_time.used_hours).to be_zero
        expect(leave_time.locked_hours).to be_zero
      end
    end

    context 'multiple LeaveTimes cover over LeaveApplication time interval' do
      before do
        create(:leave_time, :annual, user: user, quota: 50, usable_hours: 50, effective_date: Date.parse('2017-04-25'), expiration_date: Date.parse('2017-05-05'))
        create(:leave_time, :annual, user: user, quota: 50, usable_hours: 50, effective_date: Date.parse('2017-05-06'), expiration_date: Date.parse('2017-05-10'))
      end

      subject { create(:leave_application, :annual, user: user, start_time: Time.zone.local(2017, 5, 3, 9, 30), end_time: Time.zone.local(2017, 5, 12, 12, 30)) }

      it 'should create LeaveTimeUsage successfully with sufficent hours' do
        create(:leave_time, :annual, user: user, quota: 50, usable_hours: 50, effective_date: Date.parse('2017-05-11'), expiration_date: Date.parse('2017-05-15'))
        expect(subject.errors.empty?).to be_truthy
        expect(user.leave_applications.size).to be 1
        expect(subject.leave_time_usages.size).to be 3
      end

      it 'should failed to create LeaveTimeUsage with insufficient hours' do
        create(:leave_time, :annual, user: user, quota: 10, usable_hours: 10, effective_date: Date.parse('2017-05-10'), expiration_date: Date.parse('2017-05-15'))
        expect(subject.errors.empty?).to be_falsy
        expect(user.leave_applications.size).to be_zero
        expect(subject.leave_time_usages).to be_empty
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
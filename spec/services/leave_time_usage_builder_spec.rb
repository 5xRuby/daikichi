require 'rails_helper'

describe LeaveTimeUsageBuilder do
  let(:user)              { create(:user) }
  let(:start_time)        { Time.zone.local(2017, 5, 4, 9, 30) }
  let(:end_time)          { Time.zone.local(2017, 5, 9, 12, 30) }
  let(:leave_application) { create(:leave_application, :personal, user: user, start_time: start_time, end_time: end_time) }
  let(:total_used_hours)  { Daikichi::Config::Biz.within(start_time, end_time).in_hours }

  before { User.skip_callback(:create, :after, :auto_assign_leave_time) }
  after  { User.set_callback(:create, :after, :auto_assign_leave_time)  }

  describe '.leave_hours_by_date' do
    let(:effective_date)    { Date.parse('2017-05-01') }
    let(:expiration_date)   { Date.parse('2017-05-31') }

    before { create(:leave_time, :annual, user: user, quota: 100, usable_hours: 100, effective_date: effective_date, expiration_date: expiration_date) }

    it 'returns a hash to represent leave time as hours by date' do
      builder = described_class.new leave_application
      expect(builder.leave_hours_by_date).to eq({
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
        leave_application = create(:leave_application, :personal, user: user, start_time: Time.zone.local(2017, 5, 1, 9, 30), end_time: Time.zone.local(2017, 5, 5, 12, 30))
        leave_time_usage = leave_application.leave_time_usages.first
        leave_time = leave_time_usage.leave_time
        expect(leave_application.leave_time_usages.size).to eq 1
        expect(leave_time_usage.used_hours).to eq leave_application.hours
        expect(leave_time.usable_hours).to eq (quota - leave_application.hours)
        expect(leave_time.locked_hours).to eq leave_application.hours
      end

      it 'should create failed with insufficient usable hours' do
        leave_application = create(:leave_application, :personal, user: user, start_time: Time.zone.local(2017, 5, 1, 9, 30), end_time: Time.zone.local(2017, 5, 31, 12, 30))
        leave_time = user.leave_times.first
        expect(user.leave_applications).to be_empty
        expect(LeaveTimeUsage.where(leave_application: leave_application)).to be_empty
        expect(leave_time.usable_hours).to eq quota
        expect(leave_time.locked_hours).to be_zero
      end
    end

    context 'multiple LeaveTimes cover over LeaveApplication time interval' do
      before do
        create(:leave_time, :annual, user: user, quota: 50, usable_hours: 50, effective_date: Date.parse('2017-04-25'), expiration_date: Date.parse('2017-05-05'))
        create(:leave_time, :annual, user: user, quota: 50, usable_hours: 50, effective_date: Date.parse('2017-05-06'), expiration_date: Date.parse('2017-05-10'))
      end

      subject { create(:leave_application, :personal, user: user, start_time: Time.zone.local(2017, 5, 3, 9, 30), end_time: Time.zone.local(2017, 5, 12, 12, 30)) }

      it 'should create LeaveTimeUsage successfully with sufficent hours' do
        create(:leave_time, :annual, user: user, quota: 50, usable_hours: 50, effective_date: Date.parse('2017-05-11'), expiration_date: Date.parse('2017-05-15'))
        expect(subject.errors).to be_empty
        expect(user.leave_applications.size).to be 1
        expect(subject.leave_time_usages.size).to be 3
      end

      it 'should failed to create LeaveTimeUsage with insufficient hours' do
        create(:leave_time, :annual, user: user, quota: 10, usable_hours: 10, effective_date: Date.parse('2017-05-10'), expiration_date: Date.parse('2017-05-15'))
        expect(subject.errors).not_to be_empty
        expect(user.leave_applications.size).to be_zero
        expect(subject.leave_time_usages).to be_empty
      end
    end

    context 'didn\'t completely covered LeaveApplication' do
      let(:start_time) { Time.zone.local(2017, 5, 3, 9, 30) }
      let(:end_time)   { Time.zone.local(2017, 5, 12, 12, 30) }
      subject { create(:leave_application, :personal, user: user, start_time: start_time, end_time: end_time) }

      shared_examples 'not covered partially' do |part, lt_params_1, lt_params_2, error_date, lack_hours|
        it "create failed with LeaveTimes not covering the #{part} of LeaveApplication" do
          create(:leave_time, :annual, user: user, quota: 50, usable_hours: 50, effective_date: Date.parse(lt_params_1[:effective_date]), expiration_date: Date.parse(lt_params_1[:expiration_date]))
          create(:leave_time, :annual, user: user, quota: 50, usable_hours: 50, effective_date: Date.parse(lt_params_2[:effective_date]), expiration_date: Date.parse(lt_params_2[:expiration_date]))
          expect(subject.errors).not_to be_empty
          expect(subject.errors[:hours]).to include(I18n.t('activerecord.errors.models.leave_application.attributes.hours.lacking_hours', date: Date.parse(error_date), hours: lack_hours))
          expect(user.leave_applications).to be_empty
        end
      end

      it_should_behave_like 'not covered partially', 'start',  { effective_date: '2017-05-04', expiration_date: '2017-05-08' }, { effective_date: '2017-05-09', expiration_date: '2017-05-12' }, '2017-05-03', 8
      it_should_behave_like 'not covered partially', 'middle', { effective_date: '2017-05-03', expiration_date: '2017-05-07' }, { effective_date: '2017-05-09', expiration_date: '2017-05-12' }, '2017-05-08', 8
      it_should_behave_like 'not covered partially', 'end',    { effective_date: '2017-05-03', expiration_date: '2017-05-08' }, { effective_date: '2017-05-09', expiration_date: '2017-05-11' }, '2017-05-12', 3
    end

    context 'priority' do
      let(:effective_date)      { Date.parse('2017-05-01') }
      let(:expiration_date)     { Date.parse('2017-05-31') }
      let(:nearly_expired_date) { expiration_date - 1.day }
      let(:start_time)          { Time.zone.local(2017, 5, 3, 9, 30) }
      let(:end_time)            { Time.zone.local(2017, 5, 12, 12, 30) }
      subject { create(:leave_application, :personal, user: user, start_time: start_time, end_time: end_time) }

      context 'different expiration date' do
        let!(:nearly_expired_leave_time) { create(:leave_time, :annual, user: user, quota: 50, usable_hours: 50, effective_date: effective_date, expiration_date: nearly_expired_date) }
        let!(:leave_time)                { create(:leave_time, :annual, user: user, quota: 50, usable_hours: 50, effective_date: effective_date, expiration_date: expiration_date) }
        it 'should use LeaveTime where nearly to expired prior to other LeaveTimes' do
          expect(subject.errors).to be_empty
          expect(subject.leave_time_usages.size).to be 2
          nearly_expired_leave_time.reload
          leave_time.reload
          expect(nearly_expired_leave_time.usable_hours).to be_zero
          expect(nearly_expired_leave_time.locked_hours).to be 50
          expect(leave_time.usable_hours).to be 41
          expect(leave_time.locked_hours).to be 9
        end
      end

      context 'different usable_hours' do
        let!(:less_usable_hours_leave_time) { create(:leave_time, :annual, user: user, quota: 50, usable_hours: 49, locked_hours: 1, effective_date: effective_date, expiration_date: expiration_date) }
        let!(:leave_time)                   { create(:leave_time, :annual, user: user, quota: 50, usable_hours: 50, effective_date: effective_date, expiration_date: expiration_date) }
        it 'should use LeaveTime where less usable_hours prior to other LeaveTimes' do
          expect(subject.errors).to be_empty
          expect(subject.leave_time_usages.size).to be 2
          less_usable_hours_leave_time.reload
          leave_time.reload
          expect(less_usable_hours_leave_time.usable_hours).to be_zero
          expect(less_usable_hours_leave_time.locked_hours).to be 50
          expect(leave_time.usable_hours).to be 40
          expect(leave_time.locked_hours).to be 10
        end
      end

      context 'different expiration_date and usable_hours' do
        let!(:nearly_expired_leave_time)    { create(:leave_time, :annual, user: user, quota: 50, usable_hours: 50, effective_date: effective_date, expiration_date: nearly_expired_date) }
        let!(:less_usable_hours_leave_time) { create(:leave_time, :annual, user: user, quota: 50, usable_hours: 49, locked_hours: 1, effective_date: effective_date, expiration_date: expiration_date) }
        it 'should use LeaveTime where nearly to expired prior to other LeaveTime with less usable_hours' do
          expect(subject.errors).to be_empty
          expect(subject.leave_time_usages.size).to be 2
          nearly_expired_leave_time.reload
          less_usable_hours_leave_time.reload
          expect(nearly_expired_leave_time.usable_hours).to be_zero
          expect(nearly_expired_leave_time.locked_hours).to be 50
          expect(less_usable_hours_leave_time.usable_hours).to be 40
          expect(less_usable_hours_leave_time.locked_hours).to be 10
        end
      end

      context 'leave_type :sick' do
        let!(:fullpaid_sick) { create(:leave_time, :fullpaid_sick, user: user, quota: 50, usable_hours: 50, effective_date: effective_date, expiration_date: expiration_date) }
        subject { create(:leave_application, :sick, user: user, start_time: start_time, end_time: end_time) }
        it 'should use fullpaid_sick prior to halfpaid_sick' do
          halfpaid_sick = create(:leave_time, :halfpaid_sick, user: user, quota: 50, usable_hours: 50, effective_date: effective_date, expiration_date: expiration_date)
          expect(subject.errors).to be_empty
          expect(subject.leave_time_usages.size).to eq 2
          fullpaid_sick.reload
          halfpaid_sick.reload
          expect(fullpaid_sick.usable_hours).to be_zero
          expect(fullpaid_sick.locked_hours).to be 50
          expect(halfpaid_sick.usable_hours).to be 41
          expect(halfpaid_sick.locked_hours).to be 9
        end

        it 'should use fullpaid_sick prior to nearly expired halfpaid_sick' do
          nearly_expired_halfpaid_sick = create(:leave_time, :halfpaid_sick, user: user, quota: 50, usable_hours: 50, effective_date: effective_date, expiration_date: nearly_expired_date)
          expect(subject.errors).to be_empty
          expect(subject.leave_time_usages.size).to be 2
          fullpaid_sick.reload
          nearly_expired_halfpaid_sick.reload
          expect(fullpaid_sick.usable_hours).to be_zero
          expect(fullpaid_sick.locked_hours).to be 50
          expect(nearly_expired_halfpaid_sick.usable_hours).to be 41
          expect(nearly_expired_halfpaid_sick.locked_hours).to be 9
        end

        it 'should use fullpaid_sick prior to less usable_hours halfpaid_sick' do
          less_usable_hours_halfpaid_sick = create(:leave_time, :halfpaid_sick, user: user, quota: 50, usable_hours: 49, locked_hours: 1, effective_date: effective_date, expiration_date: expiration_date)
          expect(subject.errors).to be_empty
          expect(subject.leave_time_usages.size).to be 2
          fullpaid_sick.reload
          less_usable_hours_halfpaid_sick.reload
          expect(fullpaid_sick.usable_hours).to be_zero
          expect(fullpaid_sick.locked_hours).to be 50
          expect(less_usable_hours_halfpaid_sick.usable_hours).to be 40
          expect(less_usable_hours_halfpaid_sick.locked_hours).to be 10
        end
      end
    end
  end
end

# frozen_string_literal: true
require 'rails_helper'

describe LeaveTimeSummaryService do
  let!(:manager) { create(:user, :manager) }
  let!(:user) { create(:user, :employee, join_date: Time.zone.local(2018, 1, 2)) }
  let(:start_time) { Daikichi::Config::Biz.periods.after(Time.current.end_of_month.beginning_of_day - 3.days).first.start_time }
  before { Timecop.freeze(Time.zone.local(2018, 1, 2)) }

  describe 'summary total leave_time' do
    context 'same leave type' do
      let(:start_time) { Time.zone.local(2018, 1, 5, 9, 30) }
      let(:end_time) { Time.zone.local(2018, 1, 10, 18, 30) }
      it 'should calculate total leave' do
        leave_application = create(:leave_application, :personal, user: user, start_time: start_time, end_time: end_time).reload
        leave_application.approve!(create(:user, :hr))
        summary = LeaveTimeSummaryService.new(Date.current.year, Date.current.month).summary
        expect(summary[user.id]['annual']).to eq 32
      end
    end

    context 'different leave type' do
      let(:sick_start_time) { Time.zone.local(2018, 1, 5, 9, 30) }
      let(:sick_end_time) { Time.zone.local(2018, 1, 16, 18, 30) }
      let(:personal_start_time) { Time.zone.local(2018, 1, 18, 9, 30) }
      let(:personal_end_time) { Time.zone.local(2018, 1, 31, 18, 30) }
      it 'should calculate total leave times for different leave type' do
        leave_application = create(:leave_application, :sick, user: user, start_time: sick_start_time, end_time: sick_end_time).reload
        leave_application.approve!(create(:user, :hr))
        leave_application = create(:leave_application, user: user, start_time: personal_start_time, end_time: personal_end_time).reload
        leave_application.approve!(create(:user, :hr))
        summary = LeaveTimeSummaryService.new(2018, 1).summary
        expect(summary[user.id]['fullpaid_sick']).to eq 56
        expect(summary[user.id]['halfpaid_sick']).to eq 8
        expect(summary[user.id]['annual']).to eq 56
        expect(summary[user.id]['personal']).to eq 24
      end
    end

    context 'start time and end time in different month' do
      let(:start_time) { Time.zone.local(2018, 1, 25, 10, 30) }
      let(:start_time2) { Time.zone.local(2018, 1, 30, 9, 30) }
      let(:end_time) { Time.zone.local(2018, 1, 29, 18, 30) }
      let(:end_time2) { Time.zone.local(2018, 2, 9, 18, 30) }
      it 'should calculate total sick leave times in specified month' do
        leave_application = create(:leave_application, :sick, user: user, start_time: start_time, end_time: end_time).reload
        leave_application.approve!(create(:user, :hr))
        leave_application = create(:leave_application, :sick, user: user, start_time: start_time2, end_time: end_time2).reload
        leave_application.approve!(create(:user, :hr))
        summary = LeaveTimeSummaryService.new(2018, 1).summary
        expect(summary[user.id]['fullpaid_sick']).to eq 39
        summary = LeaveTimeSummaryService.new(2018, 2).summary
        expect(summary[user.id]['fullpaid_sick']).to eq 17
        expect(summary[user.id]['halfpaid_sick']).to eq 39
      end

      it 'should calculate total personal leave times in specified month' do
        create(:leave_time, :bonus, user: user, quota: 8, usable_hours: 8)
        leave_application = create(:leave_application, :personal, user: user, start_time: start_time, end_time: end_time).reload
        leave_application.approve!(create(:user, :hr))
        leave_application = create(:leave_application, :personal, user: user, start_time: start_time2, end_time: end_time2).reload
        leave_application.approve!(create(:user, :hr))
        summary = LeaveTimeSummaryService.new(2018, 1).summary
        expect(summary[user.id]['bonus']).to eq 8
        expect(summary[user.id]['annual']).to eq 31
        summary = LeaveTimeSummaryService.new(2018, 2).summary
        expect(summary[user.id]['annual']).to eq 25
        expect(summary[user.id]['personal']).to eq 31
      end
    end
  end
end

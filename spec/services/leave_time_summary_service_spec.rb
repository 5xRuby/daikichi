# frozen_string_literal: true
require 'rails_helper'

describe LeaveTimeSummaryService do
  describe 'summary total leave_time' do 
    let(:manager) { create(:user, :manager) }
    let(:user) { create(:user, :employee, join_date: Daikichi::Config::Biz.periods.after((Time.current.beginning_of_month.beginning_of_day)).first.start_time) }
    let(:start_time)      { Daikichi::Config::Biz.periods.after((Time.current.end_of_month.beginning_of_day)- 3.days).first.start_time   }
    let(:end_time)        { Daikichi::Config::Biz.periods.after(Time.current.next_month.beginning_of_month.beginning_of_day).first.start_time  }
    it "should include false if start_time and end_time cross the month" do 
      leave_application = create(:leave_application, :personal, user: user, start_time: start_time, end_time: end_time).reload
      leave_application.approve!(create(:user, :hr))
      summary = LeaveTimeSummaryService.new(Date.current.year, Date.current.month).summary
      expect(summary[user.id].values.flatten).to include(false)
    end
  end
end
# frozen_string_literal: true
require "rails_helper"

RSpec.describe LeaveTime, type: :model do
  let(:first_year_employee) { FactoryGirl.create(:first_year_employee) }
  let(:third_year_employee) { FactoryGirl.create(:third_year_employee) }
  let(:senior_employee) { FactoryGirl.create(:user, :employee, join_date: "1980-10-01") }
  let(:contractor) { FactoryGirl.create(:user, :contractor) }

  describe "init_quota" do
    context "annual leave" do
      it "first year employee should have 32 hours" do
        annual = FactoryGirl.create(:annual_leave_time, user: first_year_employee)
        annual.init_quota
        expect(annual.quota).to eq 32
      end

      it "third year employee should have 72 hours" do
        annual = FactoryGirl.create(:annual_leave_time, user: third_year_employee)
        annual.init_quota
        expect(annual.quota).to eq 72
      end

      it "senior employee should have no more than 240 hours" do
        annual = FactoryGirl.create(:annual_leave_time, user: senior_employee)
        annual.init_quota
        expect(annual.quota).to eq 240
      end

      it "non-employee have no leave time" do
        annual = FactoryGirl.create(:annual_leave_time, user: contractor)
        expect(annual.init_quota).to be_falsey
      end
    end

    context "sick leave" do
      it "first year employee should have 136 hours" do
        sick = FactoryGirl.create(:sick_leave_time, user: first_year_employee)
        sick.init_quota
        expect(sick.quota).to eq 136
      end

      it "regular employee should have 240 hours" do
        sick = FactoryGirl.create(:sick_leave_time, user: senior_employee)
        sick.init_quota
        expect(sick.quota).to eq 240
      end

      it "non-employee have no leave time" do
        sick = FactoryGirl.create(:sick_leave_time, user: contractor)
        expect(sick.init_quota).to be_falsey
      end
    end

    context "personal leave" do
      it "first year employee should have 32 hours" do
        personal = FactoryGirl.create(:personal_leave_time, user: first_year_employee)
        personal.init_quota
        expect(personal.quota).to eq 32
      end

      it "regular employee should have 56 hours" do
        personal = FactoryGirl.create(:personal_leave_time, user: senior_employee)
        personal.init_quota
        expect(personal.quota).to eq 56
      end

      it "non-employee have no leave time" do
        personal = FactoryGirl.create(:personal_leave_time, user: contractor)
        expect(personal.init_quota).to be_falsey
      end
    end

    context "bonus leave" do
      it "initial bonus leave time is 0" do
        bonus = FactoryGirl.create(:bonus_leave_time, user: senior_employee)
        bonus.init_quota
        expect(bonus.quota).to eq 0
      end

      it "non-employee have no leave time" do
        bonus = FactoryGirl.create(:bonus_leave_time, user: contractor)
        expect(bonus.init_quota).to be_falsey
      end
    end
  end
end

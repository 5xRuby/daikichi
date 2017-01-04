# frozen_string_literal: true
require "rails_helper"

RSpec.describe LeaveTime, type: :model do
  let(:first_year_employee) { FactoryGirl.create(:first_year_employee) }
  let(:third_year_employee) { FactoryGirl.create(:third_year_employee) }
  let(:senior_employee) { FactoryGirl.create(:user, :employee, join_date: 30.years.ago) }
  let(:contractor)      { FactoryGirl.create(:user, :contractor) }

  describe "init_quota" do
    context "annual leave" do
      it "first year employee should have 56 hours" do
        annual = FactoryGirl.create(:leave_time, :annual, user: first_year_employee)
        annual.init_quota
        expect(annual.quota).to eq 56 
      end

      it "third year employee should have 80 hours" do
        annual = FactoryGirl.create(:leave_time, :annual, user: third_year_employee)
        annual.init_quota
        expect(annual.quota).to eq 80 
      end

      it "employee with 3-year employee tenure should have 112 hours" do 
        annual = FactoryGirl.create(:leave_time, :annual, user: FactoryGirl.build(:employee, join_date: 3.years.ago))
        annual.init_quota
        expect(annual.quota).to eq 112 
      end

      it "employee with 4-year employee tenure should have 112 hours" do 
        annual = FactoryGirl.create(:leave_time, :annual, user: FactoryGirl.build(:employee, join_date: 4.years.ago))
        annual.init_quota
        expect(annual.quota).to eq 112 
      end

      it "employee with 5-year employee tenure should have 120 hours" do 
        annual = FactoryGirl.create(:leave_time, :annual, user: FactoryGirl.build(:employee, join_date: 5.years.ago))
        annual.init_quota
        expect(annual.quota).to eq 120
      end
      
      it "employee with 9-year employee tenure should have 120 hours" do 
        annual = FactoryGirl.create(:leave_time, :annual, user: FactoryGirl.build(:employee, join_date: 9.years.ago))
        annual.init_quota
        expect(annual.quota).to eq 120
      end

      context "employee with more than 10-year employee tenure should have extra 8 hours for each additional year" do 
        it "employee with 10-year employee tenure should have 128 hours" do 
          annual = FactoryGirl.create(:leave_time, :annual, user: FactoryGirl.build(:employee, join_date: 10.years.ago))
          annual.init_quota
          expect(annual.quota).to eq 128
        end

        it "employee with 11-year employee tenure should have 136 hours" do 
          annual = FactoryGirl.create(:leave_time, :annual, user: FactoryGirl.build(:employee, join_date: 11.years.ago))
          annual.init_quota
          expect(annual.quota).to eq 136
        end

        it "employee with 23-year employee tenure should have 232 hours" do 
          annual = FactoryGirl.create(:leave_time, :annual, user: FactoryGirl.build(:employee, join_date: 23.years.ago))
          annual.init_quota
          expect(annual.quota).to eq 232
        end
      end

      it "senior employee should have no more than 240 hours" do
        annual = FactoryGirl.create(:leave_time, :annual, user: senior_employee)
        annual.init_quota
        expect(annual.quota).to eq 240
      end

      it "non-employee have no leave time" do
        annual = FactoryGirl.create(:leave_time, :annual, user: contractor)
        expect(annual.init_quota).to be_falsey
      end
    end

    context "sick leave" do
      it "first year employee should have 136 hours" do
        #FIXME: Test will failed when encountered leap year
        sick = FactoryGirl.create(:leave_time, :sick, user: first_year_employee)
        sick.init_quota
        expect(sick.quota).to eq 144
      end

      it "regular employee should have 240 hours" do
        sick = FactoryGirl.create(:leave_time, :sick, user: senior_employee)
        sick.init_quota
        expect(sick.quota).to eq 240
      end

      it "non-employee have no leave time" do
        sick = FactoryGirl.create(:leave_time, :sick, user: contractor)
        expect(sick.init_quota).to be_falsey
      end
    end

    context "personal leave" do
      it "first year employee should have 32 hours" do
        personal = FactoryGirl.create(:leave_time, :personal, user: first_year_employee)
        personal.init_quota
        expect(personal.quota).to eq 32
      end

      it "regular employee should have 56 hours" do
        personal = FactoryGirl.create(:leave_time, :personal, user: senior_employee)
        personal.init_quota
        expect(personal.quota).to eq 56
      end

      it "non-employee have no leave time" do
        personal = FactoryGirl.create(:leave_time, :personal, user: contractor)
        expect(personal.init_quota).to be_falsey
      end
    end

    context "bonus leave" do
      it "initial bonus leave time is 0" do
        bonus = FactoryGirl.create(:leave_time, :bonus, user: senior_employee)
        bonus.init_quota
        expect(bonus.quota).to eq 0
      end

      it "non-employee have no leave time" do
        bonus = FactoryGirl.create(:leave_time, :bonus, user: contractor)
        expect(bonus.init_quota).to be_falsey
      end
    end
  end

  describe "refill" do
    let(:this_year) { Time.now.year }

    it "employee not employed for a year shouldn't get 8 hour plus" do
      annual = FactoryGirl.create(:leave_time, :annual, user: first_year_employee)
      Timecop.travel Time.local(this_year + 1, 1, 1, 0, 0, 0)
      annual.init_quota
      expect(annual.quota).to eq 56
      Timecop.return

      Timecop.travel Time.local(this_year + 1, 5, 1, 0, 0, 0)
      annual.refill
      expect(annual.quota).to eq 56
      Timecop.return
    end

    it "employee employed for a year shouldn get 8 hours plus" do
      annual = FactoryGirl.create(:leave_time, :annual, user: first_year_employee)
      Timecop.travel Time.local(this_year + 1, 1, 1, 0, 0, 0)
      annual.init_quota
      expect(annual.quota).to eq 56
      Timecop.return

      Timecop.travel Time.local(this_year + 1, 7, 1, 0, 0, 0)
      annual.refill
      expect(annual.quota).to eq 64

      annual.refill
      expect(annual.quota).not_to eq 72
      expect(annual.quota).to eq 64
      Timecop.return
    end

    it "third_year_employee won't get 8 hours plus" do
      annual = FactoryGirl.create(:leave_time, :annual, user: third_year_employee)
      Timecop.travel Time.local(this_year + 1, 1, 1, 0, 0, 0)
      annual.init_quota
      expect(annual.quota).to eq 80
      Timecop.return

      Timecop.travel Time.local(this_year + 1, 7, 1, 0, 0, 0)
      annual.refill
      expect(annual.quota).to eq 80
      Timecop.return
    end
  end
end

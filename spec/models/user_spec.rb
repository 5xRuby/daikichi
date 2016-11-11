# frozen_string_literal: true
require "rails_helper"

RSpec.describe User, type: :model do
  let(:base_year) { Time.now.year }
  let(:admin) { FactoryGirl.create(:user, :admin) }
  let(:manager) { FactoryGirl.create(:user, :manager) }
  let(:first_year_employee) { FactoryGirl.create(:first_year_employee) }
  let(:second_year_employee) { FactoryGirl.create(:second_year_employee) }
  let(:third_year_employee) { FactoryGirl.create(:third_year_employee) }
  let(:contractor) { FactoryGirl.create(:user, :contractor) }


  describe "employee seniority in years" do
    def travel_check(time, target, value)
      Timecop.travel(time)
      expect(target.seniority(base_year)).to eq value
      Timecop.return
    end

    it "user is not an employee" do
      expect(contractor.seniority(base_year)).to eq 0
    end

    it "user is a new employee" do
      travel_check(Time.local(base_year, 7, 1), first_year_employee, 1)
    end

    it "user is a second year employee employed within a year" do
      travel_check(Time.local(base_year, 3, 1), second_year_employee, 1)
    end

    it "user is a second year employee employed over a year" do
      travel_check(Time.local(base_year, 5, 1), second_year_employee, 2)
    end

    it "user is a third year employee" do
      travel_check(Time.local(base_year, 1, 1), third_year_employee, 3)
    end
  end

  describe "role check: fulltime?" do
    it "user is an employee" do
      expect(third_year_employee.fulltime?).to be_truthy
    end

    it "user is a manager" do
      expect(manager.fulltime?).to be_truthy
    end

    it "user is not an employee" do
      expect(contractor.fulltime?).to be_falsey
    end
  end
end

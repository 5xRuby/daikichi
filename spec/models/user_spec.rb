# frozen_string_literal: true
require "rails_helper"

RSpec.describe User, type: :model do
  let(:base_year) { 2016 }
  let(:admin) { FactoryGirl.create(:user, :admin) }
  let(:manager) { FactoryGirl.create(:user, :manager) }
  let(:first_year_employee) { FactoryGirl.create(:first_year_employee) }
  let(:third_year_employee) { FactoryGirl.create(:third_year_employee) }
  let(:contractor) { FactoryGirl.create(:user, :contractor) }

  describe "employee seniority in years" do
    it "user is not an employee" do
      expect(contractor.seniority(base_year)).to eq 0
    end

    it "user is a new employee" do
      expect(first_year_employee.seniority(base_year)).to eq 1
    end

    it "user is a third year employee" do
      expect(third_year_employee.seniority(base_year)).to eq 3
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

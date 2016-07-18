# frozen_string_literal: true
require "rails_helper"

RSpec.describe User, type: :model do
  let(:admin) { FactoryGirl.create(:user, :admin) }
  let(:manager) { FactoryGirl.create(:user, :manager) }
  let(:employee) { FactoryGirl.create(:user, :employee) }
  let(:freshman) { FactoryGirl.create(:user, :freshman) }
  let(:senior) { FactoryGirl.create(:user, :senior) }
  let(:contractor) { FactoryGirl.create(:user, :contractor) }

  describe "employee seniority in years" do
    it "user is not an employee" do
      expect(contractor.seniority).to eq 0
    end

    it "user is a new employee" do
      expect(freshman.seniority).to eq 1
    end

    it "user is a senior employee" do
      joined_years = Time.zone.today.year - senior.join_date.year + 1
      expect(senior.seniority).to eq joined_years
    end
  end

  describe "role check: fulltime?" do
    it "user is an employee" do
      expect(employee.fulltime?).to be_truthy
    end

    it "user is a manager" do
      expect(manager.fulltime?).to be_truthy
    end

    it "user is not an employee" do
      expect(contractor.fulltime?).to be_falsey
    end
  end
end

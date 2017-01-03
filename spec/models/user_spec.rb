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

  describe "scope" do
    describe "with_leave_application_statistics" do
      let(:year)  { Time.current.year }
      let(:month) { Time.current.month }
      let(:start_time) { WorkingHours.advance_to_working_time(Time.new(year, month, 1)) }
      let(:end_time)   { WorkingHours.return_to_working_time(start_time + 1.working.day) }
      let!(:leave_application) { FactoryGirl.create(:leave_application, :with_leave_time, start_time: start_time, end_time: end_time) }
      subject { described_class.with_leave_application_statistics(year, month) }

      shared_examples "not included in returned results" do
        it "is not included in returned results" do
          expect(subject).not_to exist
        end
      end

      context "approved leave_applications" do
        let!(:leave_application) { FactoryGirl.create(:leave_application, :approved, :with_leave_time, :annual, start_time: start_time, end_time: end_time) }

        context "within range" do
          it "is include in returned results" do
            expect(subject).to include leave_application.user
            expect(subject.first.leave_applications).to include leave_application
          end

          context "all leave_hours_within_month" do
            before do
              FactoryGirl.create(
                :leave_application, :approved, :annual,
                user: leave_application.user,
                start_time: start_time + 3.working.day,
                end_time: WorkingHours.return_to_working_time(start_time + 4.working.day)
              )
            end

            it "should all be sum up" do
              expect(subject.first.leave_applications.leave_hours_within_month(year: year, month: month)).to eq 16
            end
          end

          context "specific leave_hours_within_month" do
            before do
              FactoryGirl.create(
                :leave_application, :approved, :personal, :with_leave_time,
                user: leave_application.user,
                start_time: start_time + 3.working.day,
                end_time: WorkingHours.return_to_working_time(start_time + 4.working.day)
              )
            end

            it "only with specific leave_type will be sum up" do
              expect(subject.first.leave_applications.leave_hours_within_month(year: year, month: month, type: 'personal')).to eq 8
            end
          end
        end

        context "partially overlaps given range" do
          let(:start_time) { WorkingHours.advance_to_working_time(Time.new(year, month, 1) - 1.working.day) }
          let(:end_time)   { WorkingHours.return_to_working_time(Time.new(year, month, 1) + 3.working.day) }

          it "is include in returned results" do
            expect(subject).to include leave_application.user
            expect(subject.first.leave_applications).to include leave_application
          end

          context "all leave_hours_within_month" do
            before do
              FactoryGirl.create(
                :leave_application, :approved, :annual,
                user: leave_application.user,
                start_time: start_time + 3.working.day,
                end_time: WorkingHours.return_to_working_time(start_time + 4.working.day)
              )
            end
            it "only those overlaps will be sum up" do
              expect(subject.first.leave_applications.leave_hours_within_month(year: year, month: month)).to eq 24
            end
          end

          context "specific leave_hours_within_month" do
            before do
              FactoryGirl.create(
                :leave_application, :approved, :personal, :with_leave_time,
                user: leave_application.user,
                start_time: start_time + 3.working.day,
                end_time: WorkingHours.return_to_working_time(start_time + 4.working.day)
              )
            end
            it "only with specific leave_type will be sum up" do
              expect(subject.first.leave_applications.leave_hours_within_month(year: year, month: month, type: 'annual')).to eq 16
            end
          end
        end

        context "out of range" do
          let(:start_time) { WorkingHours.advance_to_working_time(Time.new(year, month, 1) - 2.working.day) }
          let(:end_time)   { WorkingHours.return_to_working_time(Time.new(year, month, 1) - 1.working.day) }

          include_examples "not included in returned results"
        end
      end

      context "not approved leave_applications" do
        let!(:leave_application) { FactoryGirl.create(:leave_application, :with_leave_time, start_time: start_time, end_time: end_time) }
        include_examples "not included in returned results"
      end
    end
  end

  describe "helper_method" do
    describe "role identification" do
      let(:employee) { FactoryGirl.create(:user, :employee) }
      let(:manager)  { FactoryGirl.create(:user, :manager) }
      let(:hr)  { FactoryGirl.create(:user, :hr) }

      context "is_manager?" do
        it "is true if user is manager" do
          expect(manager.is_manager?).to be_truthy
        end

        it "is false if user is not manager" do
          expect(hr.is_manager?).to be_falsey
          expect(employee.is_manager?).to be_falsey
        end
      end

      context "is_hr?" do
        it "is true if user is hr" do
          expect(hr.is_hr?).to be_truthy
        end

        it "is false if user is not hr" do
          expect(employee.is_hr?).to be_falsey
          expect(manager.is_hr?).to be_falsey
        end
      end
    end
  end
end

# frozen_string_literal: true
require "rails_helper"
RSpec.describe LeaveApplication, type: :model do
  let(:first_year_employee) { FactoryGirl.create(:first_year_employee) }
  let(:sick)     { FactoryGirl.create(:leave_time, :sick,     user: first_year_employee) }
  let(:personal) { FactoryGirl.create(:leave_time, :personal, user: first_year_employee) }
  let(:bonus)    { FactoryGirl.create(:leave_time, :bonus,    user: first_year_employee) }
  let(:annual)   { FactoryGirl.create(:leave_time, :annual,   user: first_year_employee) }
  # Monday
  let(:start_time)      { Time.new(Time.current.year, 8, 15, 9, 30, 0, "+08:00") }
  let(:one_hour_ago)    { Time.new(Time.current.year, 8, 15, 8, 30, 0, "+08:00") }
  let(:half_hour_later) { Time.new(Time.current.year, 8, 15, 10, 0, 0, "+08:00") }
  let(:one_hour_later)  { Time.new(Time.current.year, 8, 15, 10, 30, 0, "+08:00") }
  let(:two_hour_later)  { Time.new(Time.current.year, 8, 15, 11, 30, 0, "+08:00") }
  let(:one_day_later)   { Time.new(Time.current.year, 8, 16, 9, 30, 0, "+08:00") }
  let(:two_day_later)   { Time.new(Time.current.year, 8, 17, 9, 30, 0, "+08:00") }
  let(:three_day_later) { Time.new(Time.current.year, 8, 18, 9, 30, 0, "+08:00") }
  let(:four_day_later)  { Time.new(Time.current.year, 8, 19, 9, 30, 0, "+08:00") }
  let(:five_day_later)  { Time.new(Time.current.year, 8, 20, 9, 30, 0, "+08:00") }
  # 主管
  let(:manager_eddie) { FactoryGirl.create(:manager_eddie) }

  def init_quota
    annual.init_quota
    personal.init_quota
    sick.init_quota
    bonus.init_quota
    return annual, personal, sick, bonus
  end

  def leave(end_time, leave_type = :sick)
    FactoryGirl.create :leave_application, leave_type, start_time: start_time, end_time: end_time, user: first_year_employee
  end

  describe "validation" do
    let(:params) { FactotyGirl.attributes_for(:leave_application) }
    subject { described_class.new(params) }

    context "has a valid factory" do
      subject { FactoryGirl.build_stubbed(:leave_application, :with_leave_time, :annual) }
      it { expect(subject).to be_valid }
    end

    it "leave_type必填" do
      leave = LeaveApplication.new(
        start_time: start_time,
        end_time: one_hour_later,
        description: "test"
      )
      expect(leave).to be_invalid
      expect(leave.errors.messages[:leave_type].first).to eq "請選擇請假種類"
    end

    it "description必填" do
      leave = LeaveApplication.new(
        start_time: start_time,
        end_time: one_hour_later,
        leave_type: "sick"
      )
      expect(leave).to be_invalid
      expect(leave.errors.messages[:description].first).to eq "請簡述原因"
    end

    it "hours應為正整數" do
      leave = LeaveApplication.new start_time: start_time, leave_type: "sick", description: "test"
      leave.end_time = one_hour_ago
      expect(leave).to be_invalid
      expect(leave.errors.messages[:start_time].first).to eq "開始時間必須早於結束時間"

      leave.end_time = start_time
      expect(leave).to be_invalid
      expect(leave.errors.messages[:start_time].first).to eq "開始時間必須早於結束時間"

      leave.end_time = half_hour_later
      expect(leave).to be_invalid
      expect(leave.errors.messages[:end_time].first).to eq "請假的最小單位是1小時"
    end

    context "has_enough_leave_time" do
      subject { FactoryGirl.build(:leave_application) }

      it "is invalid without leave_time intialize" do
        expect(subject).not_to be_valid
        expect(subject.errors.messages[:end_time]).to include I18n.t("activerecord.errors.models.leave_application.attributes.end_time.not_enough_leave_time")
      end

      context "leave_time intialize" do
        before do
          FactoryGirl.create(:leave_time, :annual, user: subject.user, quota: 3)
        end
        it "is invalid without enough leave_time" do
          expect(subject).not_to be_valid
          expect(subject.errors.messages[:end_time]).to include I18n.t("activerecord.errors.models.leave_application.attributes.end_time.not_enough_leave_time")
        end
      end
    end

    context "valid_advanced_leave_type?" do
      context "creating a next_year leave_application" do
        context "leave_type is annual" do
          subject { FactoryGirl.build_stubbed(:leave_application, :with_leave_time, :annual, :next_year) }
          it "should be valid" do
            expect(subject).to be_valid
          end
        end

        context "leave_type is not annual" do
          subject { FactoryGirl.build_stubbed(:leave_application, :with_leave_time, :personal, :next_year) }
          it "should not be valid" do
            expect(subject).not_to be_valid
            expect(subject.errors.messages[:leave_type]).to include I18n.t("activerecord.errors.models.leave_application.attributes.leave_type.only_take_annual_leave_year_before")
          end
        end
      end
    end
  end

  describe "使用者操作" do
    context "新增病假假單" do
      it "8hr" do
        annual, personal, sick, bonus = init_quota
        quota = sick.quota

        leave = leave(one_day_later)
        expect(leave.hours).to eq 8
        expect(leave.status).to eq "pending"

        sick.reload
        expect(sick.used_hours).to eq 8
        expect(sick.usable_hours).to eq(quota - sick.used_hours)
      end

      it "超過時間, 但實質時間一樣是8hr" do
        annual, personal, sick, bonus = init_quota
        quota = sick.quota

        leave = leave(Time.new(Time.current.year, 8, 15, 23, 30, 0, "+08:00"))
        expect(leave.hours).to eq 8
        expect(leave.status).to eq "pending"

        sick.reload
        expect(sick.used_hours).to eq 8
        expect(sick.usable_hours).to eq(quota - sick.used_hours)
      end

      it "24hr" do
        annual, personal, sick, bonus = init_quota
        quota = sick.quota

        leave = leave(three_day_later)
        expect(leave.hours).to eq 24
        expect(leave.status).to eq "pending"

        sick.reload
        expect(sick.used_hours).to eq 24
        expect(sick.usable_hours).to eq(quota - sick.used_hours)
      end
    end

    context "修改病假假單" do
      it "2hr -> 8hr" do
        annual, personal, sick, bonus = init_quota

        leave = leave(two_hour_later)
        expect(leave.hours).to eq 2
        expect(leave.status).to eq "pending"

        sick.reload
        expect(sick.used_hours).to eq 2

        leave.update! end_time: one_day_later
        leave.revise!
        sick.reload
        expect(sick.used_hours).to eq 8
        expect(sick.usable_hours).to eq (sick.quota - sick.used_hours)
        expect(leave.status).to eq "pending"
      end

      it "8hr -> 2hr" do
        annual, personal, sick, bonus = init_quota

        leave = leave(one_day_later)
        expect(leave.hours).to eq 8
        expect(leave.status).to eq "pending"

        sick.reload
        expect(sick.used_hours).to eq 8

        leave.update! end_time: two_hour_later
        leave.revise!
        sick.reload
        expect(sick.used_hours).to eq 2
        expect(sick.usable_hours).to eq (sick.quota - sick.used_hours)
        expect(leave.status).to eq "pending"
      end
    end

  end

  describe "aasm狀態" do
    it "核可假單" do
      annual, personal, sick, bonus = init_quota

      leave = FactoryGirl.create :leave_application, :sick, start_time: start_time, end_time: one_day_later, user: first_year_employee
      sick.reload
      expect(sick.used_hours).to eq 8
      expect(sick.usable_hours).to eq(sick.quota - sick.used_hours)
      expect(leave.status).to eq "pending"
      expect(leave.manager_id).to eq nil

      leave.approve! manager_eddie
      expect(sick.used_hours).to eq 8
      expect(sick.usable_hours).to eq(sick.quota - sick.used_hours)
      expect(leave.status).to eq "approved"
      expect(leave.manager_id).to eq manager_eddie.id
    end

    it "否決假單" do
      annual, personal, sick, bonus = init_quota

      leave = FactoryGirl.create :leave_application, :sick, start_time: start_time, end_time: two_day_later, user: first_year_employee
      sick.reload
      expect(sick.used_hours).to eq 16
      expect(sick.usable_hours).to eq(sick.quota - sick.used_hours)
      expect(leave.status).to eq "pending"
      expect(leave.manager_id).to eq nil

      leave.reject! manager_eddie
      sick.reload
      expect(sick.used_hours).to eq 0
      expect(sick.usable_hours).to eq sick.quota
      expect(leave.status).to eq "rejected"
      expect(leave.manager_id).to eq manager_eddie.id
    end
  end

  describe "LeaveTime corresponding change" do
    let!(:leave_application) {
      FactoryGirl.create(
        :leave_application, :with_leave_time, :annual,
        start_time: 3.working.day.from_now.beginning_of_day + 9.hours  + 30.minutes,
        end_time:   3.working.day.from_now.beginning_of_day + 18.hours + 30.minutes
      )
    }

    context "leave application canceled" do
      before do
        expect(leave_application.leave_time.used_hours).to eq 8
        leave_application.cancel!
      end
      it "corresponding used_hours should return to user" do
        expect(leave_application.reload.status).to eq "canceled"
        expect(leave_application.leave_time.used_hours).to eq 0
      end
    end

    context "canceled one of multiple leave_application" do
      let!(:leave_application2) {
        FactoryGirl.create(
          :leave_application, :annual, user: leave_application.user,
          start_time: 5.working.day.from_now.beginning_of_day + 9.hours  + 30.minutes,
          end_time:   5.working.day.from_now.beginning_of_day + 18.hours + 30.minutes
        )
      }
      before do
        expect(leave_application2.reload.leave_time.used_hours).to eq 16
        leave_application2.cancel!
      end

      it "corresponding used_hours should return to user" do
        expect(leave_application2.reload.status).to eq "canceled"
        expect(leave_application.leave_time.used_hours).to eq 8
      end
    end
  end

  describe "aasm 狀態變更" do
    it "rejected -> pending" do
      annual, personal, sick, bonus = init_quota

      leave = leave(two_hour_later, :sick)
      expect(leave.hours).to eq 2
      expect(leave.status).to eq "pending"

      sick.reload
      expect(sick.used_hours).to eq 2

      leave.reject!(manager_eddie)
      expect(leave.status).to eq "rejected"

      sick.reload
      expect(sick.used_hours).to eq 0

      leave.update! end_time: one_day_later
      leave.revise!
      sick.reload
      expect(sick.used_hours).to eq 8
      expect(leave.status).to eq "pending"
    end

    it "approved -> pending" do
      annual, personal, sick, bonus = init_quota

      leave = leave(two_hour_later, :sick)
      expect(leave.hours).to eq 2
      expect(leave.status).to eq "pending"

      sick.reload
      expect(sick.used_hours).to eq 2

      leave.approve!(manager_eddie)
      expect(leave.status).to eq "approved"

      sick.reload
      expect(sick.used_hours).to eq 2

      leave.update! end_time: two_day_later
      leave.revise!
      sick.reload
      expect(sick.used_hours).to eq 16
      expect(leave.status).to eq "pending"
    end

    context "approved -> canceled" do
      let(:approved_leave_application) {
        FactoryGirl.create(
          :leave_application, :approved, :annual, :with_leave_time,
          manager: manager_eddie, user: first_year_employee)
      }

      context "canceled before happened" do
        it "should canceled successfully" do
          expect(approved_leave_application).to transition_from(:approved).to(:canceled).on_event(:cancel)
        end
      end

      context "cancel after happened" do
        let(:approved_leave_application) {
          FactoryGirl.create(
            :leave_application, :sick, :happened, :approved, :with_leave_time,
            manager: manager_eddie, user: first_year_employee)
        }
        it "should reject change of status" do
          expect { approved_leave_application.cancel }.to raise_error AASM::InvalidTransition
        end
      end
    end

    it "rejected -> canceled" do
      annual, personal, sick, bonus = init_quota
      leave = leave(three_day_later, :sick)
      expect(leave.hours).to eq 24
      expect(leave.status).to eq "pending"

      sick.reload
      expect(sick.used_hours).to eq 24

      leave.reject!(manager_eddie)
      sick.reload
      expect(sick.used_hours).to eq 0
      expect(leave.status).to eq "rejected"

      leave.cancel!
      sick.reload
      expect(sick.used_hours).to eq 0
      expect(leave.status).to eq "canceled"
    end
  end

  describe "scope" do
    let(:beginning)  { WorkingHours.advance_to_working_time(1.month.ago.beginning_of_month) }
    let(:closing)    { WorkingHours.return_to_working_time(1.month.ago.end_of_month) }
    describe ".leave_within_range" do
      let(:start_time) { beginning + 3.working.day }
      let(:end_time)   { beginning + 5.working.day }
      subject { described_class.leave_within_range(beginning, closing) }
      let!(:leave_application) {
        FactoryGirl.create(
          :leave_application, :with_leave_time,
          start_time: start_time,
          end_time:   end_time
        )
      }

      context "LeaveApplication is in specific range" do
        it "should be included in returned results" do
          expect(subject).to include(leave_application)
        end
      end

      context "LeaveApplication overlaps specific range" do
        let(:start_time) { beginning - 1.working.day }
        let(:end_time)   { beginning + 1.working.day }

        it "should be included in returned results" do
          expect(subject).to include(leave_application)
        end
      end

      context "LeaveApplication happened before specific range" do
        let(:start_time) { beginning - 2.working.day }
        let(:end_time)   { beginning - 1.working.day }
        it "should not be included in returned results" do
          expect(subject).not_to include(leave_application)
        end
      end

      context "LeaveApplication happened after specific range" do
        let(:start_time) { WorkingHours.advance_to_working_time(closing) }
        let(:end_time)   { start_time + 1.working.day }
        it "should not be included in returned results" do
          expect(subject).not_to include(leave_application)
        end
      end
    end
  end

  describe "helper method" do
    let(:beginning)  { WorkingHours.advance_to_working_time(1.month.ago.beginning_of_month) }
    let(:closing)    { WorkingHours.return_to_working_time(1.month.ago.end_of_month) }
    describe ".leave_hours_within" do
      let(:start_time) { beginning + 3.working.day }
      let(:end_time)   { beginning + 5.working.day }
      subject { described_class.leave_hours_within(beginning, closing) }

      context "within_range" do
        before do
          FactoryGirl.create(:leave_application, :with_leave_time, start_time: start_time, end_time: end_time)
        end

        it "should be sum up" do
          expect(subject).to eq 16
        end
      end

      context "partially overlaps with given range" do
        let(:start_time) { beginning - 1.working.day  }
        let(:end_time)   { WorkingHours.return_to_working_time(beginning + 1.working.day)  }

        before do
          FactoryGirl.create(:leave_application, :with_leave_time, start_time: start_time, end_time: end_time)
        end

        it "only hours in range will be sum up" do
          expect(subject).to eq 8
        end
      end

      context "out of range" do
        let(:start_time) { beginning - 2.working.day  }
        let(:end_time)   { WorkingHours.return_to_working_time(beginning - 1.working.day)  }

        before do
          FactoryGirl.create(:leave_application, :with_leave_time, start_time: start_time, end_time: end_time)
        end

        it "should be ignored" do
          expect(subject).to eq 0
        end
      end
    end

    describe "#range_exceeded?" do
      let(:start_time) { beginning + 3.working.day }
      let(:end_time)   { WorkingHours.return_to_working_time(beginning + 5.working.day) }
      let(:leave_application) {
        FactoryGirl.build_stubbed(
          :leave_application,
          start_time: start_time,
          end_time:   end_time
        )
      }
      subject { leave_application.range_exceeded?(beginning, closing) }
      context "start_time exceeds given range" do
        let(:start_time) { beginning - 1.hour }
        it { expect(subject).to be_truthy }
      end

      context "end_time exceeds given range" do
        let(:end_time) { closing + 1.hour }
        it { expect(subject).to be_truthy }
      end

      context "start_time and end_time within_range" do
        let(:start_time) { beginning }
        let(:end_time)   { closing }
        it { expect(subject).to be_falsy }
      end
    end

    describe "#is_leave_type?" do
      let(:type) { 'all' }
      let(:leave_application) { FactoryGirl.build_stubbed(:leave_application) }
      subject { leave_application.is_leave_type?(type) }
      context "all" do
        it "is true with all leave_type" do
          expect(subject).to be_truthy
        end
      end

      context "specific" do
        let(:type) { 'annual' }
        let(:leave_application) { FactoryGirl.build_stubbed(:leave_application, leave_type: type) }
        it "is true if given leave_type equals to object's leave_type" do
          expect(subject).to be_truthy
        end

        it "is false if given leave_type not equals to object's leave_type" do
          expect(leave_application.is_leave_type?('unknown')).to be_falsy
        end
      end
    end
  end
end

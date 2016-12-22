# frozen_string_literal: true
require "rails_helper"
RSpec.describe LeaveApplication, type: :model do
  let(:first_year_employee) { FactoryGirl.create(:first_year_employee) }
  let(:sick)     { FactoryGirl.create(:leave_time, :sick,     user: first_year_employee) }
  let(:personal) { FactoryGirl.create(:leave_time, :personal, user: first_year_employee) }
  let(:bonus)    { FactoryGirl.create(:leave_time, :bonus,    user: first_year_employee) }
  let(:annual)   { FactoryGirl.create(:leave_time, :annual,   user: first_year_employee) }
  # Monday
  let(:start_time) { Time.new(2016, 8, 15, 9, 30, 0, "+08:00") }
  let(:one_hour_ago) { Time.new(2016, 8, 15, 8, 30, 0, "+08:00") }
  let(:half_hour_later) { Time.new(2016, 8, 15, 10, 0, 0, "+08:00") }
  let(:one_hour_later) { Time.new(2016, 8, 15, 10, 30, 0, "+08:00") }
  let(:two_hour_later) { Time.new(2016, 8, 15, 11, 30, 0, "+08:00") }
  let(:one_day_later) { Time.new(2016, 8, 16, 9, 30, 0, "+08:00") }
  let(:two_day_later) { Time.new(2016, 8, 17, 9, 30, 0, "+08:00") }
  let(:three_day_later) { Time.new(2016, 8, 18, 9, 30, 0, "+08:00") }
  let(:four_day_later) { Time.new(2016, 8, 19, 9, 30, 0, "+08:00") }
  let(:five_day_later) { Time.new(2016, 8, 20, 9, 30, 0, "+08:00") }
  # 主管
  let(:manager_eddie) { FactoryGirl.create(:manager_eddie) }

  def init_quota
    annual.init_quota
    personal.init_quota
    sick.init_quota
    bonus.init_quota
    return annual, personal, sick, bonus
  end

  def leave(end_time, leave_type = :sick_leave )
    FactoryGirl.create :leave_application, leave_type, start_time: start_time, end_time: end_time, user: first_year_employee
  end

  describe "validation" do
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
  end

  describe "使用者操作" do
    context "新增病假假單" do
      it "8hr" do
        annual, personal, sick, bonus = init_quota
        quota = sick.quota

        leave = leave(one_day_later, :sick_leave)
        expect(leave.hours).to eq 8
        expect(leave.status).to eq "pending"

        sick.reload
        expect(sick.used_hours).to eq 8
        expect(sick.usable_hours).to eq(quota - sick.used_hours)
      end

      it "超過時間, 但實質時間一樣是8hr" do
        annual, personal, sick, bonus = init_quota
        quota = sick.quota

        leave = leave(Time.new(2016, 8, 15, 23, 30, 0, "+08:00"), :sick_leave)
        expect(leave.hours).to eq 8
        expect(leave.status).to eq "pending"

        sick.reload
        expect(sick.used_hours).to eq 8
        expect(sick.usable_hours).to eq(quota - sick.used_hours)
      end

      it "24hr" do
        annual, personal, sick, bonus = init_quota
        quota = sick.quota

        leave = leave(three_day_later, :sick_leave)
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

        leave = leave(two_hour_later, :sick_leave)
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

        leave = leave(one_day_later, :sick_leave)
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

      leave = FactoryGirl.create :leave_application, :sick_leave, start_time: start_time, end_time: one_day_later, user: first_year_employee
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

      leave = FactoryGirl.create :leave_application, :sick_leave, start_time: start_time, end_time: two_day_later, user: first_year_employee
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

    context "取消特休假單" do
      it "24hr" do
        annual, personal, sick, bonus = init_quota

        leave = leave(three_day_later, :bonus_leave)
        expect(leave.hours).to eq 24
        expect(leave.status).to eq "pending"

        bonus.reload
        expect(bonus.used_hours).to eq 24

        leave.cancel!
        annual.reload
        expect(annual.used_hours).to eq 0
        expect(leave.status).to eq "canceled"
      end

      it "有兩張假單，取消了其中一張" do
        annual, personal, sick, bonus = init_quota

        leave = leave(one_day_later, :bonus_leave)
        leave2 = leave(two_day_later, :bonus_leave)
        expect(leave.hours).to eq 8
        expect(leave.status).to eq "pending"
        expect(leave2.hours).to eq 16
        expect(leave2.status).to eq "pending"

        bonus.reload
        expect(bonus.used_hours).to eq 24

        leave.cancel!
        bonus.reload
        expect(bonus.used_hours).to eq 16
        expect(leave.status).to eq "canceled"
      end
    end
  end

  describe "aasm 狀態變更" do
    it "rejected -> pending" do
      annual, personal, sick, bonus = init_quota

      leave = leave(two_hour_later, :sick_leave)
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

      leave = leave(two_hour_later, :sick_leave)
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
          :leave_application, start_time: 3.days.since.beginning_of_hour, end_time: 5.days.since.beginning_of_hour ,
          status: 'approved', manager: manager_eddie, user: first_year_employee,
          leave_type: :sick)
      }

      before do
        init_quota
      end

      context "canceled before happened" do
        it "should canceled successfully" do
          expect(approved_leave_application).to transition_from(:approved).to(:canceled).on_event(:cancel)
        end
      end

      context "cancel after happened" do
        let(:approved_leave_application) {
          FactoryGirl.create(
            :leave_application, :sick_leave, :happened, :approved,
            manager: manager_eddie, user: first_year_employee)
        }
        it "should reject change of status" do
          expect { approved_leave_application.cancel }.to raise_error AASM::InvalidTransition
        end
      end
    end

    it "rejected -> canceled" do
      annual, personal, sick, bonus = init_quota
      leave = leave(three_day_later, :sick_leave)
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
end

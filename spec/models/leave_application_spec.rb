# frozen_string_literal: true
require "rails_helper"
RSpec.describe LeaveApplication, type: :model do
  describe "validation" do
    let(:start_time) { Time.new(2016, 8, 17, 9, 30, 0, "+08:00") }

    it "leave_type必填" do
      leave = LeaveApplication.new(
        start_time: start_time,
        end_time: start_time + 60 * 60,
        description: "test"
      )
      expect(leave).to be_invalid
      expect(leave.errors.messages[:leave_type].first).to eq "請選擇請假種類"
    end

    it "description必填" do
      leave = LeaveApplication.new(
        start_time: start_time,
        end_time: start_time + 60 * 60,
        leave_type: "sick"
      )
      expect(leave).to be_invalid
      expect(leave.errors.messages[:description].first).to eq "請簡述原因"
    end

    it "hours應為正整數" do
      leave = LeaveApplication.new(
        start_time: start_time,
        leave_type: "sick",
        description: "test"
      )
      # 8/17 9:30 ~ 8/16 10:30
      leave.end_time = Time.new(2016, 8, 16, 10, 30, 0, "+08:00")
      expect(leave).to be_invalid
      expect(leave.errors.messages[:start_time].first).to eq "開始時間必須早於結束時間"

      # 8/17 9:30 ~ 8/17 9:30
      leave.end_time = start_time
      expect(leave).to be_invalid
      expect(leave.errors.messages[:start_time].first).to eq "開始時間必須早於結束時間"

      # 8/17 9:30 ~ 8/17 10:00
      leave.end_time = Time.new(2016, 8, 17, 10, 0, 0, "+08:00")
      expect(leave).to be_invalid
      expect(leave.errors.messages[:end_time].first).to eq "請假的最小單位是1小時"
    end
  end

  describe "使用者操作" do
    let(:a_first_year_employee) { FactoryGirl.create(:a_first_year_employee) }
    let(:start_time) { Time.new(2016, 8, 17, 9, 30, 0, "+08:00") }

    context "新增假單" do
      let(:sick) { FactoryGirl.create(:sick_leave_time, user: a_first_year_employee) }

      it "8/17 09:30 ~ 8/17 17:30, 7hr" do
        sick.init_quota
        quota = sick.quota

        FactoryGirl.create(
          :sick_leave,
          start_time: start_time,
          end_time: Time.new(2016, 8, 17, 17, 30, 0, "+08:00"),
          user: a_first_year_employee
        )
        sick.reload
        expect(sick.used_hours).to eq 7
        expect(sick.usable_hours).to eq(quota - sick.used_hours)
      end

      it "8/17 09:30 ~ 8/17 23:30, 8hr" do
        sick.init_quota
        quota = sick.quota

        FactoryGirl.create(
          :sick_leave,
          start_time: start_time,
          end_time: Time.new(2016, 8, 17, 23, 30, 0, "+08:00"),
          user: a_first_year_employee
        )
        sick.reload
        expect(sick.used_hours).to eq 8
        expect(sick.usable_hours).to eq(quota - sick.used_hours)
      end

      it "8/17 09:30 ~ 8/21 18:30, 24hr" do
        sick.init_quota
        quota = sick.quota

        FactoryGirl.create(
          :sick_leave,
          start_time: start_time,
          end_time: Time.new(2016, 8, 21, 18, 30, 0, "+08:00"),
          user: a_first_year_employee
        )
        sick.reload
        expect(sick.used_hours).to eq 24
        expect(sick.usable_hours).to eq(quota - sick.used_hours)
      end

      it "8/21 09:30 ~ 8/28 09:30, 40hr" do
        sick.init_quota
        quota = sick.quota

        FactoryGirl.create(
          :sick_leave,
          start_time: Time.new(2016, 8, 21, 9, 30, 0, "+08:00"),
          end_time: Time.new(2016, 8, 28, 9, 30, 0, "+08:00"),
          user: a_first_year_employee
        )
        sick.reload
        expect(sick.used_hours).to eq 40
        expect(sick.usable_hours).to eq(quota - sick.used_hours)
      end
    end

    context "修改假單" do
      let(:personal) { FactoryGirl.create(:personal_leave_time, user: a_first_year_employee) }

      it "結束時間 8/17 11:30 -> 8/17 18:30" do
        personal.init_quota
        leave = FactoryGirl.create(
          :personal_leave,
          start_time: start_time,
          end_time: Time.new(2016, 8, 17, 11, 30, 0, "+08:00"),
          user: a_first_year_employee
        )
        personal.reload
        expect(personal.used_hours).to eq 2
        expect(leave.status).to eq "pending"

        leave.update! end_time: Time.new(2016, 8, 17, 18, 30, 0, "+08:00")
        leave.revise!
        personal.reload
        expect(personal.used_hours).to eq 8
        expect(leave.status).to eq "pending"
      end
    end

    context "取消假單" do
      let(:bonus) { FactoryGirl.create(:bonus_leave_time, user: a_first_year_employee) }

      it "有兩張假單，取消了其中一張8/17 09:30 ~ 8/18 10:30 pending假單" do
        bonus.init_quota
        leave = FactoryGirl.create(
          :bonus_leave,
          start_time: start_time,
          end_time: Time.new(2016, 8, 18, 10, 30, 0, "+08:00"),
          user: a_first_year_employee
        )
        FactoryGirl.create(
          :bonus_leave,
          start_time: start_time,
          end_time: Time.new(2016, 8, 19, 9, 30, 0, "+08:00"),
          user: a_first_year_employee
        )
        bonus.reload
        expect(bonus.used_hours).to eq 25

        leave.cancel!
        bonus.reload
        expect(bonus.used_hours).to eq 16
      end
    end
  end

  describe "主管操作" do
    let(:a_first_year_employee) { FactoryGirl.create(:a_first_year_employee) }
    let(:annual) { FactoryGirl.create(:annual_leave_time, user: a_first_year_employee) }
    let(:manager_eddie) { FactoryGirl.create(:manager_eddie) }

    # 8/17 14:30 ~ 8/19 18:30
    it "主管核可假單" do
      annual.init_quota
      quota = annual.quota

      leave = FactoryGirl.create(
        :annual_leave,
        start_time: Time.new(2016, 8, 17, 14, 30, 0, "+08:00"),
        end_time: Time.new(2016, 8, 19, 18, 30, 0, "+08:00"),
        user: a_first_year_employee
      )
      annual.reload
      expect(annual.used_hours).to eq 20
      expect(annual.usable_hours).to eq(quota - annual.used_hours)
      expect(leave.status).to eq "pending"
      expect(leave.manager_id).to eq nil

      leave.approve! manager_eddie
      expect(annual.used_hours).to eq 20
      expect(annual.usable_hours).to eq(quota - annual.used_hours)
      expect(leave.status).to eq "approved"
      expect(leave.manager_id).to eq manager_eddie.id
    end

    # 8/17 14:30 ~ 8/17 18:30
    it "主管否決假單" do
      annual.init_quota
      quota = annual.quota

      leave = FactoryGirl.create(
        :annual_leave,
        start_time: Time.new(2016, 8, 17, 14, 30, 0, "+08:00"),
        end_time: Time.new(2016, 8, 19, 18, 30, 0, "+08:00"),
        user: a_first_year_employee
      )
      annual.reload
      expect(annual.used_hours).to eq 20
      expect(annual.usable_hours).to eq(quota - annual.used_hours)
      expect(leave.status).to eq "pending"
      expect(leave.manager_id).to eq nil

      leave.reject! manager_eddie
      annual.reload
      expect(annual.used_hours).to eq 0
      expect(annual.usable_hours).to eq quota
      expect(leave.status).to eq "rejected"
      expect(leave.manager_id).to eq manager_eddie.id
    end
  end

  describe "綜合操作，主管審核後員工再次操作" do
    let(:start_time) { Time.new(2016, 8, 17, 9, 30, 0, "+08:00") }
    let(:a_first_year_employee) { FactoryGirl.create(:a_first_year_employee) }
    let(:personal) { FactoryGirl.create(:personal_leave_time, user: a_first_year_employee) }
    let(:manager_eddie) { FactoryGirl.create(:manager_eddie) }

    # 8/17 9:30 ~ 8/17 11:30 --> 8/17 9:30 ~ 8/17 12:30
    it "狀態rejected -> pending" do
      personal.init_quota
      leave = FactoryGirl.create(
        :personal_leave,
        start_time: start_time,
        end_time: Time.new(2016, 8, 17, 11, 30, 0, "+08:00"),
        user: a_first_year_employee
      )
      personal.reload
      expect(leave.status).to eq "pending"
      expect(personal.used_hours).to eq 2

      leave.reject!(manager_eddie)
      personal.reload
      expect(leave.status).to eq "rejected"
      expect(personal.used_hours).to eq 0

      leave.update! end_time: Time.new(2016, 8, 17, 12, 30, 0, "+08:00")
      leave.revise!
      personal.reload
      expect(leave.status).to eq "pending"
      expect(personal.used_hours).to eq 3
    end

    # 8/17 9:30 ~ 8/17 11:30 --> 8/17 9:30 ~ 8/19 12:30
    it "狀態approved -> pending" do
      personal.init_quota
      leave = FactoryGirl.create(
        :personal_leave,
        start_time: start_time,
        end_time: Time.new(2016, 8, 17, 11, 30, 0, "+08:00"),
        user: a_first_year_employee
      )
      personal.reload
      expect(leave.status).to eq "pending"
      expect(personal.used_hours).to eq 2

      leave.approve!(manager_eddie)
      expect(leave.status).to eq "approved"
      expect(personal.used_hours).to eq 2

      leave.update! end_time: Time.new(2016, 8, 19, 12, 30, 0, "+08:00")
      leave.revise!
      personal.reload
      expect(leave.status).to eq "pending"
      expect(personal.used_hours).to eq 19
    end

    # 8/17 09:30 ~ 8/18 10:30
    it "取消approved假單" do
      personal.init_quota
      leave = FactoryGirl.create(
        :personal_leave,
        start_time: start_time,
        end_time: Time.new(2016, 8, 18, 10, 30, 0, "+08:00"),
        user: a_first_year_employee
      )
      personal.reload
      expect(personal.used_hours).to eq 9

      leave.approve!(manager_eddie)
      expect(leave.status).to eq "approved"

      leave.cancel!
      personal.reload
      expect(personal.used_hours).to eq 0
    end

    # 8/17 09:30 ~ 8/18 10:30
    it "取消rejected假單" do
      personal.init_quota
      leave = FactoryGirl.create(
        :personal_leave,
        start_time: start_time,
        end_time: Time.new(2016, 8, 18, 10, 30, 0, "+08:00"),
        user: a_first_year_employee
      )
      personal.reload
      expect(personal.used_hours).to eq 9

      leave.reject!(manager_eddie)
      personal.reload
      expect(personal.used_hours).to eq 0
      expect(leave.status).to eq "rejected"

      leave.cancel!
      personal.reload
      expect(personal.used_hours).to eq 0
    end
  end
end

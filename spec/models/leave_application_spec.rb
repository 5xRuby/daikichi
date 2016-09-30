# frozen_string_literal: true
require "rails_helper"
RSpec.describe LeaveApplication, type: :model do
  let(:first_year_employee) { FactoryGirl.create(:first_year_employee) }
  let(:sick) { FactoryGirl.create(:sick_leave_time, user: first_year_employee) }
  let(:personal) { FactoryGirl.create(:personal_leave_time, user: first_year_employee) }
  let(:bonus) { FactoryGirl.create(:bonus_leave_time, user: first_year_employee) }
  let(:annual) { FactoryGirl.create(:annual_leave_time, user: first_year_employee) }
  # Monday
  let(:start_time) { Time.new(2016, 8, 15, 9, 30, 00, "+08:00") }
  let(:one_day_later) { Time.new(2016, 8, 16, 9, 30, 00, "+08:00") }
  let(:two_day_later) { Time.new(2016, 8, 17, 9, 30, 00, "+08:00") }
  let(:three_day_later) { Time.new(2016, 8, 18, 9, 30, 00, "+08:00") }
  let(:four_day_later) { Time.new(2016, 8, 19, 9, 30, 00, "+08:00") }
  let(:five_day_later) { Time.new(2016, 8, 20, 9, 30, 00, "+08:00") }

  describe "validation" do
    let(:one_hour_ago) { Time.new(2016, 8, 15, 8, 30, 00, "+08:00") }
    let(:half_hour_later) { Time.new(2016, 8, 15, 10, 00, 00, "+08:00") }
    let(:one_hour_later) { Time.new(2016, 8, 15, 10, 30, 00, "+08:00") }

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
      leave = LeaveApplication.new( start_time: start_time, leave_type: "sick", description: "test" )
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
        sick.init_quota
        quota = sick.quota

        FactoryGirl.create( :sick_leave, start_time: start_time, end_time: one_day_later, user: first_year_employee )
        sick.reload
        expect(sick.used_hours).to eq 8
        expect(sick.usable_hours).to eq (quota - sick.used_hours)
      end

      it "超過時間, 但實質時間一樣是8hr" do
        sick.init_quota
        quota = sick.quota

        FactoryGirl.create(
          :sick_leave,
          start_time: start_time,
          end_time: Time.new(2016, 8, 15, 23, 30, 0, "+08:00"),
          user: first_year_employee
        )
        sick.reload
        expect(sick.used_hours).to eq 8
        expect(sick.usable_hours).to eq (quota - sick.used_hours)
      end

      it "24hr" do
        sick.init_quota
        quota = sick.quota

        FactoryGirl.create( :sick_leave, start_time: start_time, end_time: three_day_later, user: first_year_employee )
        sick.reload
        expect(sick.used_hours).to eq 24
        expect(sick.usable_hours).to eq (quota - sick.used_hours)
      end

      it "40hr" do
        sick.init_quota
        quota = sick.quota

        FactoryGirl.create( :sick_leave, start_time: start_time, end_time: five_day_later, user: first_year_employee )
        sick.reload
        expect(sick.used_hours).to eq 40
        expect(sick.usable_hours).to eq (quota - sick.used_hours)
      end
    end

    context "新增事假假單" do
      it "24hr < 年假可用的時數" do
        personal.init_quota
        annual.init_quota

        FactoryGirl.create( :personal_leave, start_time: start_time, end_time: three_day_later, user: first_year_employee )
        personal.reload
        annual.reload
        expect(annual.used_hours).to eq 24
        expect(personal.used_hours).not_to eq 24
        expect(personal.used_hours).to eq 0
      end

      it "請 32 小時 == 年假可用的時數" do
        personal.init_quota
        annual.init_quota
        annual_quota = annual.quota

        FactoryGirl.create( :personal_leave, start_time: start_time, end_time: four_day_later, user: first_year_employee )
        personal.reload
        annual.reload
        expect(annual.used_hours).to eq 32
        expect(personal.used_hours).not_to eq 32
        expect(personal.used_hours).to eq 0
      end

      it "請 40 小時 > 年假可用的時數" do
        personal.init_quota
        annual.init_quota
        annual_quota = annual.quota

        FactoryGirl.create( :personal_leave, start_time: start_time, end_time: five_day_later, user: first_year_employee )
        personal.reload
        annual.reload
        expect(annual.quota).to eq 32
        expect(annual.used_hours).to eq 32
        expect(personal.used_hours).not_to eq 32
        expect(personal.used_hours).to eq 8
      end
    end

    context "修改病假假單" do
      let(:two_hour_later) { Time.new(2016, 8, 15, 11, 30, 00, "+08:00") }

      it "2hr -> 8hr" do
        sick.init_quota
        leave = FactoryGirl.create( :sick_leave, start_time: start_time, end_time: two_hour_later, user: first_year_employee )
        sick.reload
        expect(sick.used_hours).to eq 2
        expect(leave.status).to eq "pending"

        leave.update! end_time: one_day_later
        leave.revise!
        sick.reload
        expect(sick.used_hours).to eq 8
        expect(leave.status).to eq "pending"
      end

      it "8hr -> 2hr" do
        sick.init_quota
        leave = FactoryGirl.create( :sick_leave, start_time: start_time, end_time: one_day_later, user: first_year_employee )
        sick.reload
        expect(sick.used_hours).to eq 8
        expect(leave.status).to eq "pending"

        leave.update! end_time: two_hour_later
        leave.revise!
        sick.reload
        expect(sick.used_hours).to eq 2
        expect(leave.status).to eq "pending"
      end
    end

    context "修改事假假單" do
      it "16hr -> 24hr, 年假時數(16hr)還可以扣" do
        personal.init_quota
        annual.init_quota

        leave = FactoryGirl.create( :personal_leave, start_time: start_time, end_time: two_day_later, user: first_year_employee )
        personal.reload
        annual.reload
        expect(annual.used_hours).to eq 16
        expect(personal.used_hours).to eq 0

        leave.update! end_time: three_day_later
        leave.revise!
        personal.reload
        annual.reload
        expect(annual.used_hours).to eq 24
        expect(personal.used_hours).to eq 0
      end

      it "16hr -> 24hr, 年假時數(2hr)不夠, 開始扣事假" do
        personal.init_quota
        annual.init_quota
        annual.update! used_hours: 14, usable_hours: annual.quota - 14
        expect(annual.used_hours).to eq 14
        expect(personal.used_hours).to eq 0

        leave = FactoryGirl.create( :personal_leave, start_time: start_time, end_time: two_day_later, user: first_year_employee )
        personal.reload
        annual.reload
        expect(annual.used_hours).to eq 30
        expect(personal.used_hours).to eq 0

        leave.update! end_time: three_day_later
        leave.revise!
        personal.reload
        annual.reload
        expect(annual.used_hours).to eq 32
        expect(personal.used_hours).to eq 6
      end

      it "16 小時 -> 24 小時, 年假時數(0hr)早沒了, 直接扣事假 " do
        personal.init_quota
        annual.init_quota
        annual.update! used_hours: 32, usable_hours: annual.quota - 32
        expect(annual.used_hours).to eq 32

        leave = FactoryGirl.create( :personal_leave, start_time: start_time, end_time: two_day_later, user: first_year_employee )
        personal.reload
        annual.reload
        expect(annual.used_hours).to eq 32
        expect(personal.used_hours).to eq 16

        leave.update! end_time: three_day_later
        leave.revise!
        personal.reload
        annual.reload
        expect(annual.used_hours).to eq 32
        expect(personal.used_hours).to eq 24
      end

      it "24hr -> 16hr, 補回事假" do
        personal.init_quota
        annual.init_quota
        annual.update! used_hours: 32, usable_hours: annual.quota - 32
        expect(annual.used_hours).to eq 32
        expect(personal.used_hours).to eq 0

        leave = FactoryGirl.create( :personal_leave, start_time: start_time, end_time: three_day_later, user: first_year_employee )
        personal.reload
        annual.reload
        expect(annual.used_hours).to eq 32
        expect(personal.used_hours).to eq 24

        leave.update! end_time: two_day_later
        leave.revise!
        personal.reload
        annual.reload
        expect(annual.used_hours).to eq 32
        expect(personal.used_hours).to eq 16
        expect(personal.usable_hours).to eq (personal.quota - 16)
      end

      it "24hr -> 8hr, 補回事假, 再補年假" do
        personal.init_quota
        annual.init_quota
        annual.update! used_hours: 16, usable_hours: annual.quota - 16
        expect(annual.used_hours).to eq 16
        expect(personal.used_hours).to eq 0

        leave = FactoryGirl.create( :personal_leave, start_time: start_time, end_time: three_day_later, user: first_year_employee )
        personal.reload
        annual.reload
        expect(annual.used_hours).to eq 32
        expect(personal.used_hours).to eq 8

        leave.update! end_time: one_day_later
        leave.revise!
        personal.reload
        annual.reload
        expect(annual.used_hours).to eq 24
        expect(personal.used_hours).to eq 0
      end
    end

    context "取消事假假單" do
      it "24hr, 先還事假時數" do
        personal.init_quota
        annual.init_quota
        annual.update! used_hours: 32, usable_hours: annual.quota - 32
        expect(annual.used_hours).to eq 32
        expect(personal.used_hours).to eq 0

        leave = FactoryGirl.create( :personal_leave, start_time: start_time, end_time: three_day_later, user: first_year_employee )
        personal.reload
        annual.reload
        expect(annual.used_hours).to eq 32
        expect(personal.used_hours).to eq 24

        leave.cancel!
        personal.reload
        annual.reload
        expect(annual.used_hours).to eq 32
        expect(personal.used_hours).to eq 0
      end

      it "24hr, 還一些事假時數, 剩餘還給年假時數" do
        personal.init_quota
        annual.init_quota
        annual.update! used_hours: 24, usable_hours: annual.quota - 24
        expect(annual.used_hours).to eq 24
        expect(personal.used_hours).to eq 0

        leave = FactoryGirl.create( :personal_leave, start_time: start_time, end_time: three_day_later, user: first_year_employee )
        personal.reload
        annual.reload
        expect(annual.used_hours).to eq 32
        expect(personal.used_hours).to eq 16

        leave.cancel!
        personal.reload
        annual.reload
        expect(annual.used_hours).to eq 24
        expect(personal.used_hours).to eq 0
      end

      it "24hr, 全部還給年假時數" do
        personal.init_quota
        annual.init_quota

        leave = FactoryGirl.create( :personal_leave, start_time: start_time, end_time: three_day_later, user: first_year_employee )
        annual.reload
        expect(annual.used_hours).to eq 24

        leave.cancel!
        annual.reload
        expect(annual.used_hours).to eq 0
      end
    end

    context "取消特休假單" do
      it "有兩張假單，取消了其中一張" do
        bonus.init_quota
        leave1 = FactoryGirl.create( :bonus_leave, start_time: start_time, end_time: one_day_later, user: first_year_employee )
        leave2 = FactoryGirl.create( :bonus_leave, start_time: start_time, end_time: two_day_later, user: first_year_employee )
        bonus.reload
        expect(bonus.used_hours).to eq 24

        leave1.cancel!
        bonus.reload
        expect(bonus.used_hours).to eq 16
      end
    end
  end

  describe "主管操作" do
    let(:manager_eddie) { FactoryGirl.create(:manager_eddie) }

    it "主管核可假單" do
      sick.init_quota

      leave = FactoryGirl.create( :sick_leave, start_time: start_time, end_time: one_day_later, user: first_year_employee )
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

    it "主管否決假單" do
      sick.init_quota
      quota = sick.quota

      leave = FactoryGirl.create( :sick_leave, start_time: start_time, end_time: two_day_later, user: first_year_employee )
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

  describe "綜合操作，主管審核後員工再次操作" do
    let(:manager_eddie) { FactoryGirl.create(:manager_eddie) }
    let(:two_hour_later) { Time.new(2016, 8, 15, 11, 30, 00, "+08:00") }

    it "狀態rejected -> pending" do
      sick.init_quota

      leave = FactoryGirl.create( :sick_leave, start_time: start_time, end_time: two_hour_later, user: first_year_employee )
      sick.reload
      expect(leave.status).to eq "pending"
      expect(sick.used_hours).to eq 2

      leave.reject!(manager_eddie)
      sick.reload
      expect(leave.status).to eq "rejected"
      expect(sick.used_hours).to eq 0

      leave.update! end_time: one_day_later
      leave.revise!
      sick.reload
      expect(leave.status).to eq "pending"
      expect(sick.used_hours).to eq 8
    end

    it "狀態approved -> pending" do
      sick.init_quota

      leave = FactoryGirl.create( :sick_leave, start_time: start_time, end_time: two_hour_later, user: first_year_employee )
      sick.reload
      expect(leave.status).to eq "pending"
      expect(sick.used_hours).to eq 2

      leave.approve!(manager_eddie)
      expect(leave.status).to eq "approved"
      expect(sick.used_hours).to eq 2

      leave.update! end_time: two_day_later
      leave.revise!
      sick.reload
      expect(leave.status).to eq "pending"
      expect(sick.used_hours).to eq 16
    end

    it "取消approved假單" do
      sick.init_quota

      leave = FactoryGirl.create( :sick_leave, start_time: start_time, end_time: three_day_later, user: first_year_employee )
      sick.reload
      expect(sick.used_hours).to eq 24

      leave.approve!(manager_eddie)
      expect(leave.status).to eq "approved"

      leave.cancel!
      sick.reload
      expect(sick.used_hours).to eq 0
      expect(leave.status).to eq "canceled"
    end

    it "取消rejected假單" do
      sick.init_quota
      leave = FactoryGirl.create( :sick_leave, start_time: start_time, end_time: three_day_later, user: first_year_employee )
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

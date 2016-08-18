require "rails_helper"

RSpec.describe LeaveApplication, type: :model do
  describe "validation" do
    let(:start_time) { Time.new(2016, 8, 17, 9, 30, 0, "+08:00") }
    let(:start_time_pass_one_hour) { start_time + 3600 }

    it "leave_type必填" do
      leave = LeaveApplication.new(
        start_time: start_time,
        end_time: start_time_pass_one_hour,
        description: "test"
      )
      expect(leave).to be_invalid
      expect(leave.errors.messages[:leave_type].first).to eq "請選擇請假種類"
    end

    it "description必填" do
      leave = LeaveApplication.new(
        start_time: start_time,
        end_time: start_time_pass_one_hour,
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
      # end_time is 8/16 10:30
      leave.end_time = Time.new(2016, 8, 16, 10, 30, 0, "+08:00")
      expect(leave).to be_invalid
      expect(leave.errors.messages[:start_time].first).to eq "開始時間必須早於結束時間"

      # start_time and end_time are same
      leave.end_time = start_time
      expect(leave).to be_invalid
      expect(leave.errors.messages[:start_time].first).to eq "開始時間必須早於結束時間"

      # end_time is 8/17 10:00
      leave.end_time = Time.new(2016, 8, 17, 10, 00, 0, "+08:00")
      expect(leave).to be_invalid
      expect(leave.errors.messages[:end_time].first).to eq "請假的最小單位是1小時"
    end
  end

  describe "新增假單" do
    let(:a_first_year_employee) { FactoryGirl.create(:a_first_year_employee) }
    let(:sick) { FactoryGirl.create(:sick_leave_time, user: a_first_year_employee) }
    let(:start_time) { Time.new(2016, 8, 17, 9, 30, 0, "+08:00") }

    it "09:30 ~ 17:30, 7hr" do
      sick.init_quota
      quota = sick.quota

      leave = FactoryGirl.create(
        :sick_leave,
        start_time: start_time,
        end_time: Time.new(2016, 8, 17, 17, 30, 0, "+08:00"),
        user: a_first_year_employee
      )
      sick.reload
      expect(sick.used_hours).to eq 7
      expect(sick.usable_hours).to eq (quota - sick.used_hours)
    end

    it "09:30 ~ 23:30, 8hr" do
      sick.init_quota
      quota = sick.quota

      leave = FactoryGirl.create(
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

      leave = FactoryGirl.create(
        :sick_leave,
        start_time: start_time,
        end_time: Time.new(2016, 8, 21, 18, 30, 00, "+08:00"),
        user: a_first_year_employee
      )
      sick.reload
      expect(sick.used_hours).to eq 24
      expect(sick.usable_hours).to eq(quota - sick.used_hours)
    end

    it "8/21 09:30 ~ 8/28 09:30, 40hr" do
      sick.init_quota
      quota = sick.quota

      leave = FactoryGirl.create(
        :sick_leave,
        start_time: Time.new(2016, 8, 21, 9, 30, 00, "+08:00"),
        end_time: Time.new(2016, 8, 28, 9, 30, 00, "+08:00"),
        user: a_first_year_employee
      )
      sick.reload
      expect(sick.used_hours).to eq 40
      expect(sick.usable_hours).to eq(quota - sick.used_hours)
    end

  end

  describe "修改假單" do
    let(:a_first_year_employee) { FactoryGirl.create(:a_first_year_employee) }
    let(:personal) { FactoryGirl.create(:personal_leave_time, user: a_first_year_employee) }
    let(:start_time) { Time.new(2016, 8, 17, 9, 30, 0, "+08:00") }

    it "結束時間 8/17 11:30 -> 8/17 18:30" do
      personal.init_quota
      quota = personal.quota

      leave = FactoryGirl.create(
        :personal_leave,
        start_time: start_time,
        end_time: Time.new(2016, 8, 17, 11, 30, 00, "+08:00"),
        user: a_first_year_employee
      )
      personal.reload
      expect(personal.used_hours).to eq 2

      leave.end_time = Time.new(2016, 8, 17, 18, 30, 00, "+08:00")
      leave.save!
      personal.reload
      expect(personal.used_hours).to eq(8)
    end

  end


  describe "主管審核" do
    let(:a_first_year_employee) { FactoryGirl.create(:a_first_year_employee) }
    let(:annual) { FactoryGirl.create(:annual_leave_time, user: a_first_year_employee) }
    let(:manager_eddie) { FactoryGirl.create(:manager_eddie) }

    it "主管核可假單" do
      annual.init_quota
      quota = annual.quota

      leave = FactoryGirl.create(
        :annual_leave,
        start_time: Time.new(2016, 8, 17, 14, 30, 00, "+08:00"),
        end_time: Time.new(2016, 8, 19, 18, 30, 00, "+08:00"),
        user: a_first_year_employee)
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

    it "主管否決假單" do
      annual.init_quota
      quota = annual.quota

      leave = FactoryGirl.create(
        :annual_leave,
        start_time: Time.new(2016, 8, 17, 14, 30, 00, "+08:00"),
        end_time: Time.new(2016, 8, 19, 18, 30, 00, "+08:00"),
        user: a_first_year_employee)
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

  describe "主管審核後員工再次修改, rejected -> pending" do
    let(:start_time) { Time.new(2016, 8, 17, 9, 30, 0, "+08:00") }
    let(:a_first_year_employee) { FactoryGirl.create(:a_first_year_employee) }
    let(:personal) { FactoryGirl.create(:personal_leave_time, user: a_first_year_employee) }
    let(:manager_eddie) { FactoryGirl.create(:manager_eddie) }

    it "員工修改假單, rejected -> pending" do
      personal.init_quota
      leave = FactoryGirl.create(
        :personal_leave,
        start_time: start_time,
        end_time: Time.new(2016, 8, 17, 11, 30, 00, "+08:00"),
        user: a_first_year_employee
      )
      personal.reload
      expect(leave.status).to eq "pending"

      leave.reject!(manager_eddie)
      expect(leave.status).to eq "rejected"

      leave.revise!
      expect(leave.status).to eq "pending"
    end

    it "員工修改假單, approved -> pending" do
      personal.init_quota
      leave = FactoryGirl.create(
        :personal_leave,
        start_time: start_time,
        end_time: Time.new(2016, 8, 17, 11, 30, 00, "+08:00"),
        user: a_first_year_employee
      )
      personal.reload
      expect(leave.status).to eq "pending"

      leave.approve!(manager_eddie)
      expect(leave.status).to eq "approved"

      leave.revise!
      expect(leave.status).to eq "pending"
    end

    it "員工修改假單, pending -> pending" do
      personal.init_quota
      leave = FactoryGirl.create(
        :personal_leave,
        start_time: start_time,
        end_time: Time.new(2016, 8, 17, 11, 30, 00, "+08:00"),
        user: a_first_year_employee
      )
      personal.reload
      expect(leave.status).to eq "pending"

      leave.revise!
      expect(leave.status).to eq "pending"
    end
  end

  describe "取消假單" do
    let(:a_first_year_employee) { FactoryGirl.create(:a_first_year_employee) }
    let(:sick) { FactoryGirl.create(:sick_leave_time, user: a_first_year_employee) }
    let(:start_time) { Time.new(2016, 8, 17, 9, 30, 0, "+08:00") }
    let(:manager_eddie) { FactoryGirl.create(:manager_eddie) }

    it "有兩張假單，取消了其中一張8/17 09:30 ~ 8/18 10:30 pending假單" do
      sick.init_quota
      leave1 = FactoryGirl.create(
        :sick_leave,
        start_time: start_time,
        end_time: Time.new(2016, 8, 18, 10, 30, 00, "+08:00"),
        user: a_first_year_employee
      )
      leave2 = FactoryGirl.create(
        :sick_leave,
        start_time: start_time,
        end_time: Time.new(2016, 8, 19, 9, 30, 00, "+08:00"),
        user: a_first_year_employee
      )
      sick.reload
      expect(sick.used_hours).to eq 25

      leave1.cancel!
      sick.reload
      expect(sick.used_hours).to eq 16
    end

    it "取消8/17 09:30 ~ 8/18 10:30 approved假單" do
      sick.init_quota
      leave = FactoryGirl.create(
        :sick_leave,
        start_time: start_time,
        end_time: Time.new(2016, 8, 18, 10, 30, 00, "+08:00"),
        user: a_first_year_employee
      )
      sick.reload
      expect(sick.used_hours).to eq 9

      leave.approve!(manager_eddie)
      expect(leave.status).to eq "approved"

      leave.cancel!
      sick.reload
      expect(sick.used_hours).to eq 0
    end

    it "取消8/17 09:30 ~ 8/18 10:30 rejected假單" do
      sick.init_quota
      leave = FactoryGirl.create(
        :sick_leave,
        start_time: start_time,
        end_time: Time.new(2016, 8, 18, 10, 30, 00, "+08:00"),
        user: a_first_year_employee
      )
      sick.reload
      expect(sick.used_hours).to eq 9

      leave.reject!(manager_eddie)
      sick.reload
      expect(sick.used_hours).to eq 0
      expect(leave.status).to eq "rejected"

      leave.cancel!
      sick.reload
      expect(sick.used_hours).to eq 0
    end
  end
end

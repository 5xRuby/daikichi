require 'rails_helper'

RSpec.describe LeaveTimeUsage, type: :model do
  describe "#associations" do
    it { is_expected.to belong_to(:leave_time) }
    it { is_expected.to belong_to(:leave_application) }
  end

  describe "#callback" do
    context "should lock LeaveTime usable_hours after LeaveTimeUsage created" do
      it { is_expected.to callback(:lock_leave_time_hours).after(:create) }
    end
  end
end

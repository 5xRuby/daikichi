require 'rails_helper'

RSpec.describe LeaveTimeUsage, type: :model do
  describe "#associations" do
    it { is_expected.to belong_to(:leave_time) }
    it { is_expected.to belong_to(:leave_application) }
  end
end

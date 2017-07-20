# frozen_string_literal: true
require 'rails_helper'
RSpec.describe LeaveHoursByDate, type: :model do
  describe '#validations' do
    context 'has a valid factory' do
      subject { build_stubbed(:leave_hours_by_date) }
      it { expect(subject).to be_valid }
    end

    it { is_expected.to validate_presence_of(:leave_application) }
    it { is_expected.to validate_presence_of(:date) }
    it { is_expected.to validate_presence_of(:hours) }
    it { is_expected.to validate_numericality_of(:hours).only_integer.is_greater_than(0) }
    it { is_expected.to validate_uniqueness_of(:date).scoped_to(:leave_application_id) }
  end
end

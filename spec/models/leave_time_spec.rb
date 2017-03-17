# frozen_string_literal: true
require 'rails_helper'

RSpec.describe LeaveTime, type: :model do
  let(:first_year_employee) { FactoryGirl.create(:first_year_employee) }
  let(:third_year_employee) { FactoryGirl.create(:third_year_employee) }
  let(:senior_employee) { FactoryGirl.create(:user, :employee, join_date: 30.years.ago) }
  let(:contractor)      { FactoryGirl.create(:user, :contractor) }

  describe '#associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:leave_applications) }
  end

  describe '#validations' do
    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:leave_type) }
    it { is_expected.to validate_presence_of(:effective_date) }
    it { is_expected.to validate_presence_of(:expiration_date) }
    it { is_expected.to validate_presence_of(:quota) }
    it { is_expected.to validate_numericality_of(:quota).only_integer.is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_presence_of(:usable_hours) }
    it { is_expected.to validate_numericality_of(:usable_hours).only_integer.is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:used_hours).only_integer.is_greater_than_or_equal_to(0) }

    context '#positive_range' do
      subject { described_class.new(params) }

      context 'expiration_date earlier than effective_date' do
        let(:params) do
          FactoryGirl.attributes_for(:leave_time,
                                     effective_date:  Time.current.strftime('%Y-%m-%d'),
                                     expiration_date:  1.day.ago .strftime('%Y-%m-%d'))
        end
        it 'is invalid' do
          expect(subject.valid?).to be_falsey
          expect(subject.errors.messages[:effective_date]). to include I18n.t('activerecord.errors.models.leave_time.attributes.effective_date.range_should_be_positive')
        end
      end
    end
  end

  describe '.scope' do
    let(:beginning) { Time.current }
    let(:ending)    { 1.year.since }
    let(:effective_date)  { beginning - 10.days }
    let(:expiration_date) { beginning + 15.days }
    let!(:leave_time) { FactoryGirl.create(:leave_time, :annual, effective_date: effective_date, expiration_date: expiration_date) }

    describe '.overlaps' do
      subject { described_class.overlaps(beginning, ending) }

      context 'partially overlaps' do
        it 'is include in returned results' do
          expect(subject).to include leave_time
        end
      end

      context 'totally overlaps' do
        let(:effective_date)  { beginning }
        let(:expiration_date) { ending }
        it 'is include in returned results' do
          expect(subject).to include leave_time
        end
      end

      context 'not overlaps at all' do
        context 'before given range' do
          let(:effective_date)  { beginning - 10.days }
          let(:expiration_date) { beginning - 5.days }
          it 'is not include in returned results' do
            expect(subject).not_to include leave_time
          end
        end

        context 'after given range' do
          let(:effective_date)  { ending + 5.days }
          let(:expiration_date) { ending + 10.days }
          it 'is not include in returned results' do
            expect(subject).not_to include leave_time
          end
        end
      end
    end

    describe '.effective' do
      context 'no specific date given' do
        subject { described_class.effective }

        context 'records overlaps with given date' do
          let(:effective_date)  { 3.days.ago }
          let(:expiration_date) { Time.current }
          it 'is include in returned results' do
            expect(subject).to include leave_time
          end
        end

        context 'records not overlaps with give date' do
          let(:effective_date)  { beginning - 3.days }
          let(:expiration_date) { beginning - 1.day }
          it 'is not include in returned results' do
            expect(subject).not_to include leave_time
          end
        end
      end

      context 'a specific date given' do
        let(:base_date) { 2.days.since }
        subject { described_class.effective(base_date) }

        context 'records overlaps with given date' do
          let(:effective_date)  { base_date - 2.days }
          let(:expiration_date) { base_date }
          it 'is include in returned results' do
            expect(subject).to include leave_time
          end
        end

        context 'records not overlaps with given date' do
          let(:effective_date)  { base_date + 1.day }
          let(:expiration_date) { base_date + 2.days }
          it 'is not include in returned results' do
            expect(subject).not_to include leave_time
          end
        end
      end
    end
  end
end

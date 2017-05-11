# frozen_string_literal: true
require 'rails_helper'

RSpec.describe LeaveTime, type: :model do
  let(:first_year_employee) { create(:first_year_employee) }
  let(:third_year_employee) { create(:third_year_employee) }
  let(:senior_employee) { create(:user, :employee, join_date: 30.years.ago) }
  let(:contractor)      { create(:user, :contractor) }

  describe '#associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:leave_time_usages) }
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
          attributes_for(:leave_time,
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

  describe '.hours' do
    describe 'lock hours' do
      let(:leave_time) { create(:leave_time, :bonus, quota: 50, usable_hours: 50) }

      context 'without bang' do
        it 'locks hour without saving the record' do
          leave_time.lock_hours 5
          expect(leave_time.usable_hours).to eq 45
          expect(leave_time.locked_hours).to eq 5
          expect(leave_time.used_hours).to eq 0

          actual_record = described_class.find(leave_time.id)
          expect(actual_record.usable_hours).to eq 50
          expect(actual_record.locked_hours).to eq 0
          expect(actual_record.used_hours).to eq 0
        end
      end

      context 'with bang' do
        it 'locks hour with saving the record' do
          leave_time.lock_hours! 5
          expect(leave_time.usable_hours).to eq 45
          expect(leave_time.locked_hours).to eq 5
          expect(leave_time.used_hours).to eq 0

          actual_record = described_class.find(leave_time.id)
          expect(actual_record.usable_hours).to eq 45
          expect(actual_record.locked_hours).to eq 5
          expect(actual_record.used_hours).to eq 0
        end
      end
    end

    describe 'unlock hours' do
      let(:leave_time) { create(:leave_time, :bonus, quota: 50, usable_hours: 30, locked_hours: 10, used_hours: 10) }
      context 'with bang' do
        it 'unlocks hour without saving the record' do
          leave_time.unlock_hours 7
          expect(leave_time.usable_hours).to eq 37
          expect(leave_time.locked_hours).to eq 3
          expect(leave_time.used_hours).to eq 10

          actual_record = described_class.find(leave_time.id)
          expect(actual_record.usable_hours).to eq 30
          expect(actual_record.locked_hours).to eq 10
          expect(actual_record.used_hours).to eq 10
        end
      end
      
      context 'without bang' do
        it 'unlocks hour with saving the record' do
          leave_time.unlock_hours! 7
          expect(leave_time.usable_hours).to eq 37
          expect(leave_time.locked_hours).to eq 3
          expect(leave_time.used_hours).to eq 10

          actual_record = described_class.find(leave_time.id)
          expect(actual_record.usable_hours).to eq 37
          expect(actual_record.locked_hours).to eq 3
          expect(actual_record.used_hours).to eq 10
        end
      end
    end

    describe 'use hours' do
      let(:leave_time) { create(:leave_time, :bonus, quota: 50, usable_hours: 20, locked_hours: 10, used_hours: 20) }

      context 'without bang' do
        it 'uses hour without saving the record' do
          leave_time.use_hours 7
          expect(leave_time.usable_hours).to eq 20
          expect(leave_time.locked_hours).to eq 3
          expect(leave_time.used_hours).to eq 27

          actual_record = described_class.find(leave_time.id)
          expect(actual_record.usable_hours).to eq 20
          expect(actual_record.locked_hours).to eq 10
          expect(actual_record.used_hours).to eq 20
        end
      end

      context 'with bang' do
        it 'uses hour with saving the record' do
          leave_time.use_hours! 7
          expect(leave_time.usable_hours).to eq 20
          expect(leave_time.locked_hours).to eq 3
          expect(leave_time.used_hours).to eq 27

          actual_record = described_class.find(leave_time.id)
          expect(actual_record.usable_hours).to eq 20
          expect(actual_record.locked_hours).to eq 3
          expect(actual_record.used_hours).to eq 27
        end
      end
    end

    describe 'unuse hours' do
      let(:leave_time) { create(:leave_time, :bonus, quota: 50, usable_hours: 20, locked_hours: 10, used_hours: 20) }
      context 'with bang' do
        it 'unuses hour without saving the record' do
          leave_time.unuse_hours 12
          expect(leave_time.usable_hours).to eq 32
          expect(leave_time.locked_hours).to eq 10
          expect(leave_time.used_hours).to eq 8

          actual_record = described_class.find(leave_time.id)
          expect(actual_record.usable_hours).to eq 20
          expect(actual_record.locked_hours).to eq 10
          expect(actual_record.used_hours).to eq 20
        end
      end
      
      context 'without bang' do
        it 'unuses hour with saving the record' do
          leave_time.unuse_hours! 12
          expect(leave_time.usable_hours).to eq 32
          expect(leave_time.locked_hours).to eq 10
          expect(leave_time.used_hours).to eq 8

          actual_record = described_class.find(leave_time.id)
          expect(actual_record.usable_hours).to eq 32
          expect(actual_record.locked_hours).to eq 10
          expect(actual_record.used_hours).to eq 8
        end
      end
    end
  end

  describe '.scope' do
    let(:beginning) { Time.current }
    let(:ending)    { 1.year.since }
    let(:effective_date)  { beginning - 10.days }
    let(:expiration_date) { beginning + 15.days }
    let!(:leave_time) { create(:leave_time, :annual, effective_date: effective_date, expiration_date: expiration_date) }

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

      context 'boundary overlaps' do
        context 'only the beginning of the scope' do
          let(:effective_date)  { beginning - 5.days }
          let(:expiration_date) { beginning }
          it 'should include LeaveTime when expiration date is beginning of the scope' do
            expect(subject).to include leave_time
          end
        end

        context 'before a day of beginning of the scope' do
          let(:effective_date)  { beginning - 5.days }
          let(:expiration_date) { beginning - 1.day }
          it 'not include LeaveTime when expiration date is one day before beginning of the scope' do
            expect(subject).not_to include leave_time
          end
        end

        context 'only the end of the scope' do
          let(:effective_date)  { ending }
          let(:expiration_date) { ending + 5.days }
          it 'should include LeaveTime when effective date is end of the scope' do
            expect(subject).to include leave_time
          end
        end

        context 'after a day of end of the scope' do
          let(:effective_date)  { ending + 1.day }
          let(:expiration_date) { ending + 5.days }
          it 'not include LeaveTime when effective date is one day after end of the scope' do
            expect(subject).not_to include leave_time
          end
        end
      end
    end

    describe ".cover?" do
      context "date is between effective and expiration date range" do
        it 'is true in LeaveTime date range' do
          date = Time.current.to_date
          expect(leave_time.cover?(date)).to be true
        end
      end

      context "date is on the effective or expiration date range edge" do
        it 'is true on effective date' do
          expect(leave_time.cover?(effective_date)).to be true
        end

        it 'is true on expiration date' do
          expect(leave_time.cover?(expiration_date)).to be true
        end
      end

      context "date is before effective date" do
        it 'is false before effective date' do
          date = effective_date - 1.day
          expect(leave_time.cover?(date)).to be false
        end
      end

      context "date is after expiration date" do
        it 'is false after expiration date' do
          date = expiration_date + 1.day
          expect(leave_time.cover?(date)).to be false
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

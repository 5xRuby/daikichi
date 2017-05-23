# frozen_string_literal: true
require 'rails_helper'
RSpec.describe LeaveApplication, type: :model do
  let(:first_year_employee) { create(:first_year_employee) }
  let(:sick)     { create(:leave_time, :sick,     user: first_year_employee) }
  let(:personal) { create(:leave_time, :personal, user: first_year_employee) }
  let(:bonus)    { create(:leave_time, :bonus,    user: first_year_employee) }
  let(:annual)   { create(:leave_time, :annual,   user: first_year_employee) }
  # Monday
  let(:start_time)      { Time.zone.local(Time.current.year, 8, 15, 9, 30, 0) }
  let(:one_hour_ago)    { Time.zone.local(Time.current.year, 8, 15, 8, 30, 0) }
  let(:half_hour_later) { Time.zone.local(Time.current.year, 8, 15, 10, 0, 0) }
  let(:one_hour_later)  { Time.zone.local(Time.current.year, 8, 15, 10, 30, 0) }

  describe '#associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:manager).with_foreign_key(:manager_id) }
    it { is_expected.to have_many(:leave_times).through(:leave_time_usages) }
    it { is_expected.to have_many(:leave_time_usages) }
  end

  describe 'validation' do
    let(:params) { FactotyGirl.attributes_for(:leave_application) }
    subject { described_class.new(params) }

    context 'has a valid factory' do
      subject { build(:leave_application, :with_leave_time, :annual) }
      it { expect(subject).to be_valid }
    end

    it 'leave_type必填' do
      leave = LeaveApplication.new(
        start_time: start_time,
        end_time: one_hour_later,
        description: 'test'
      )
      expect(leave).to be_invalid
      expect(leave.errors.messages[:leave_type].first).to eq '請選擇請假種類'
    end

    it 'description必填' do
      leave = LeaveApplication.new(
        start_time: start_time,
        end_time: one_hour_later,
        leave_type: 'sick'
      )
      expect(leave).to be_invalid
      expect(leave.errors.messages[:description].first).to eq '請簡述原因'
    end

    it 'hours應為正整數' do
      leave = LeaveApplication.new start_time: start_time, leave_type: 'sick', description: 'test'
      leave.end_time = one_hour_ago
      expect(leave).to be_invalid
      expect(leave.errors.messages[:start_time].first).to eq '開始時間必須早於結束時間'

      leave.end_time = start_time
      expect(leave).to be_invalid
      expect(leave.errors.messages[:start_time].first).to eq '開始時間必須早於結束時間'
    end

    describe 'hours_should_be_positive_integer' do
      context 'minimum unit' do
        let(:params) do
          attributes_for(:leave_application,
                         start_time: Time.zone.local(2017, 1, 3, 10, 0),
                         end_time:   Time.zone.local(2017, 1, 3, 10, 59))
        end
        it 'is an hour' do
          expect(subject).to be_invalid
          expect(subject.errors.messages[:end_time]).to include I18n.t('activerecord.errors.models.leave_application.attributes.end_time.not_integer')
        end
      end
    end
  end

  describe 'callback' do
    context 'should create LeaveTimeUsage after LeaveApplication created' do
      it { is_expected.to callback(:create_leave_time_usages).after(:create) }
    end

    context 'create_leave_time_usage' do
      let(:user)              { create(:user) }
      let(:effective_date)    { Time.zone.local(2017, 5, 1) }
      let(:expiration_date)   { Time.zone.local(2017, 5, 15) }
      let(:start_time)        { Time.zone.local(2017, 5, 1, 9, 30) }
      let(:end_time)          { Time.zone.local(2017, 5, 5, 12, 30) }
      let(:total_leave_hours) { Daikichi::Config::Biz.within(start_time, end_time).in_hours }
      before { user.leave_times.destroy_all }
      it 'should successfully create LeaveTimeUsage on sufficient LeaveTime hours' do
        lt = user.leave_times.create(leave_type: 'annual', quota: total_leave_hours, usable_hours: total_leave_hours, effective_date: effective_date, expiration_date: expiration_date)
        la = user.leave_applications.create(leave_type: 'annual', start_time: start_time, end_time: end_time, description: 'Test string')
        leave_time_usage = la.leave_time_usages.first
        leave_time = leave_time_usage.leave_time
        expect(leave_time_usage.used_hours).to eq total_leave_hours
        expect(leave_time.usable_hours).to eq 0
        expect(leave_time.used_hours).to eq 0
        expect(leave_time.locked_hours).to eq total_leave_hours
      end

      it 'should not create LeaveTimeUsage when insufficient LeaveTime hours' do
        lt = user.leave_times.create(leave_type: 'annual', quota: total_leave_hours - 1, usable_hours: total_leave_hours - 1, effective_date: effective_date, expiration_date: expiration_date)
        la = user.leave_applications.create!(leave_type: 'annual', start_time: start_time, end_time: end_time, description: 'Test string')
        leave_time = LeaveTime.find(lt.id)
        expect(la.leave_time_usages.any?).to be false
        expect(leave_time.usable_hours).to eq (total_leave_hours - 1)
        expect(leave_time.used_hours).to eq 0
        expect(leave_time.locked_hours).to eq 0
      end
    end
  end

  describe 'scope' do
    let(:beginning)  { Daikichi::Config::Biz.periods.after(1.month.ago.beginning_of_month).first.start_time }
    let(:closing)    { Daikichi::Config::Biz.periods.before(1.month.ago.end_of_month).first.end_time }
    describe '.leave_within_range' do
      let(:start_time) { Daikichi::Config::Biz.time(3, :days).after(beginning) }
      let(:end_time)   { Daikichi::Config::Biz.time(5, :days).after(beginning) }
      subject { described_class.leave_within_range(beginning, closing) }
      let!(:leave_application) do
        create(
          :leave_application, :with_leave_time,
          start_time: start_time,
          end_time:   end_time
        )
      end

      context 'LeaveApplication is in specific range' do
        it 'should be included in returned results' do
          expect(subject).to include(leave_application)
        end
      end

      context 'LeaveApplication overlaps specific range' do
        let(:start_time) { Daikichi::Config::Biz.time(1, :day).before(beginning) }
        let(:end_time)   { Daikichi::Config::Biz.time(1, :day).after(beginning) }

        it 'should be included in returned results' do
          expect(subject).to include(leave_application)
        end
      end

      context 'LeaveApplication happened before specific range' do
        let(:start_time) { Daikichi::Config::Biz.time(2, :days).before(beginning) }
        let(:end_time)   { Daikichi::Config::Biz.time(1, :day).before(beginning) }
        it 'should not be included in returned results' do
          expect(subject).not_to include(leave_application)
        end
      end

      context 'LeaveApplication happened after specific range' do
        let(:start_time) { Daikichi::Config::Biz.periods.after(closing).first.start_time }
        let(:end_time)   { Daikichi::Config::Biz.time(1, :day).after(start_time) }
        it 'should not be included in returned results' do
          expect(subject).not_to include(leave_application)
        end
      end
    end
  end

  describe 'helper method' do
    let(:beginning)  { Daikichi::Config::Biz.periods.after(1.month.ago.beginning_of_month).first.start_time }
    let(:closing)    { Daikichi::Config::Biz.periods.before(1.month.ago.end_of_month).first.end_time }
    describe '.leave_hours_within' do
      let(:start_time) { Daikichi::Config::Biz.time(3, :days).after(beginning) }
      let(:end_time)   { Daikichi::Config::Biz.time(5, :days).after(beginning) }
      subject { described_class.leave_hours_within(beginning, closing) }

      context 'within_range' do
        before do
          create(:leave_application, :with_leave_time, start_time: start_time, end_time: end_time)
        end

        it 'should be sum up' do
          expect(subject).to eq 16
        end
      end

      context 'partially overlaps with given range' do
        let(:start_time) { Daikichi::Config::Biz.time(1, :day).before(beginning) }
        let(:end_time)   { Daikichi::Config::Biz.periods.before(Daikichi::Config::Biz.time(1, :day).after(beginning)).first.end_time }

        before do
          create(:leave_application, :with_leave_time, start_time: start_time, end_time: end_time)
        end

        it 'only hours in range will be sum up' do
          expect(subject).to eq 8
        end
      end

      context 'out of range' do
        let(:start_time) { Daikichi::Config::Biz.time(2, :days).before(beginning) }
        let(:end_time)   { Daikichi::Config::Biz.periods.before(Daikichi::Config::Biz.time(1, :day).before(beginning)).first.end_time }

        before do
          create(:leave_application, :with_leave_time, start_time: start_time, end_time: end_time)
        end

        it 'should be ignored' do
          expect(subject).to eq 0
        end
      end
    end

    describe '#range_exceeded?' do
      let(:start_time) { Daikichi::Config::Biz.time(3, :days).after(beginning) }
      let(:end_time)   { Daikichi::Config::Biz.periods.before(Daikichi::Config::Biz.time(5, :days).after(beginning)).first.end_time }
      let(:leave_application) do
        build_stubbed(
          :leave_application,
          start_time: start_time,
          end_time:   end_time
        )
      end
      subject { leave_application.range_exceeded?(beginning, closing) }
      context 'start_time exceeds given range' do
        let(:start_time) { beginning - 1.hour }
        it { expect(subject).to be_truthy }
      end

      context 'end_time exceeds given range' do
        let(:end_time) { closing + 1.hour }
        it { expect(subject).to be_truthy }
      end

      context 'start_time and end_time within_range' do
        let(:start_time) { beginning }
        let(:end_time)   { closing }
        it { expect(subject).to be_falsy }
      end
    end

    describe '#is_leave_type?' do
      let(:type) { 'all' }
      let(:leave_application) { build_stubbed(:leave_application) }
      subject { leave_application.is_leave_type?(type) }
      context 'all' do
        it 'is true with all leave_type' do
          expect(subject).to be_truthy
        end
      end

      context 'specific' do
        let(:type) { 'annual' }
        let(:leave_application) { build_stubbed(:leave_application, leave_type: type) }
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

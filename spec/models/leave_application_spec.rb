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
    # let(:params) { FactoryGirl.attributes_for(:leave_application) }
    subject { described_class.new(params) }

    context 'has a valid factory' do
      subject { build(:leave_application, :with_leave_time, :personal) }
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

    describe 'application should not overlaps other pending or approved applications under same user scope' do
      let(:user)            { create(:user, :hr) }
      let(:effective_date)  { Time.zone.local(2017, 5, 1).to_date }
      let(:expiration_date) { Time.zone.local(2017, 5, 31).to_date }
      let(:start_time)      { Time.zone.local(2017, 5, 9, 12, 30) }
      let(:end_time)        { Time.zone.local(2017, 5, 11, 14, 30) }

      before do
        User.skip_callback(:create, :after, :auto_assign_leave_time)
        create(:leave_time, :annual, user: user, quota: 50, usable_hours: 50, effective_date: effective_date, expiration_date: expiration_date)
      end
      after { User.set_callback(:create, :after, :auto_assign_leave_time) }

      subject { build(:leave_application, :personal, user: user, start_time: beginning, end_time: ending) }

      shared_examples 'invalid' do |overlap_section, status|
        it "should be invalid when overlaps #{overlap_section} of the #{status} leave application" do
          la = create(:leave_application, :personal, status, user: user, start_time: start_time, end_time: end_time, description: 'test string')
          expect(subject.valid?).to be_falsy
          expect(subject.errors[:base]).to include I18n.t(
            'activerecord.errors.models.leave_application.attributes.base.overlap_application',
            leave_type: described_class.human_enum_value(:leave_type, la.leave_type),
            start_time: la.start_time.to_formatted_s(:month_date),
            end_time:   la.end_time.to_formatted_s(:month_date),
            link:       Rails.application.routes.url_helpers.leave_application_path(id: la.id)
          )
        end
      end

      context 'overlaps other applications\' start_time' do
        let(:beginning) { start_time - 1.day }
        let(:ending)    { start_time + 1.hour }
        it_should_behave_like 'invalid', 'after start_time', :pending
        it_should_behave_like 'invalid', 'after start_time', :approved
      end

      context 'overlaps other applications\' end_time' do
        let(:beginning) { end_time - 1.hour }
        let(:ending)    { end_time + 1.day }
        it_should_behave_like 'invalid', 'before end_time', :pending
        it_should_behave_like 'invalid', 'before end_time', :approved
      end

      shared_examples 'valid' do |boundary, status|
        it "is valid to overlap on #{boundary} of the other #{status} application" do
          create(:leave_application, :personal, status, user: user, start_time: start_time, end_time: end_time, description: 'test string')
          expect(subject.valid?).to be_truthy
        end
      end

      context 'overlaps only on other applications\' start_time' do
        let(:beginning) { start_time - 1.day }
        let(:ending)    { start_time }
        it_should_behave_like 'valid', 'start_time', :pending
        it_should_behave_like 'valid', 'start_time', :approved
      end

      context 'overlaps only on other applications\' end_time' do
        let(:beginning) { end_time }
        let(:ending)    { end_time + 1.day }
        it_should_behave_like 'valid', 'end_time', :pending
        it_should_behave_like 'valid', 'end_time', :approved
      end
    end
  end

  describe 'aasm' do
    let(:manager) { create(:user, :manager) }
    shared_examples 'transitions' do |params|
      let(:leave_application) { create(:leave_application, params[:from]).reload }
      describe 'without bang' do
        it "transition from #{params[:from]} to #{params[:to]} with action #{params[:with_action]}" do
          expect(leave_application.send(:"#{params[:from]}?")).to be_truthy
          expect(leave_application.send(:"may_#{params[:with_action]}?")).to be_truthy
          leave_application.send params[:with_action], (params[:manager_required] ? manager : nil)
          expect(leave_application.send(:"#{params[:to]}?")).to be_truthy
        end

        it "should not update state when using AASM method #{params[:with_action]} without bang" do
          leave_application.send params[:with_action], (params[:manager_required] ? manager : nil)
          expect(leave_application.send(:"#{params[:to]}?")).to be_truthy
          leave_application.reload
          expect(leave_application.send(:"#{params[:from]}?")).to be_truthy
        end
      end

      describe 'bang method' do
        it "transition from #{params[:from]} to #{params[:to]} with action #{params[:with_action]}!" do
          expect(leave_application.send(:"#{params[:from]}?")).to be_truthy
          expect(leave_application.send(:"may_#{params[:with_action]}?")).to be_truthy
          leave_application.send :"#{params[:with_action]}!", (params[:manager_required] ? manager : nil)
          expect(leave_application.send(:"#{params[:to]}?")).to be_truthy
        end

        it "should update state when using AASM method #{params[:with_action]}" do
          leave_application.send params[:with_action], (params[:manager_required] ? manager : nil)
          expect(leave_application.send(:"#{params[:to]}?")).to be_truthy
          leave_application.reload
          expect(leave_application.send(:"#{params[:from]}?")).to be_truthy
        end
      end
    end

    it_should_behave_like 'transitions', from: :pending,  to: :approved, with_action: :approve, manager_required: true
    it_should_behave_like 'transitions', from: :pending,  to: :canceled, with_action: :cancel
    it_should_behave_like 'transitions', from: :pending,  to: :rejected, with_action: :reject,  manager_required: true
    it_should_behave_like 'transitions', from: :approved, to: :rejected, with_action: :reject,  manager_required: true
    it_should_behave_like 'transitions', from: :pending,  to: :pending,  with_action: :revise
    it_should_behave_like 'transitions', from: :approved, to: :pending,  with_action: :revise

    describe 'conditional transition' do
      let(:user)            { create(:user, :employee) }
      let(:effective_date)  { Time.zone.local(2017, 6, 1).to_date  }
      let(:expiration_date) { Time.zone.local(2017, 6, 30).to_date }
      let(:start_time)      { Time.zone.local(2017, 6, 1, 9, 30)   }
      let(:end_time)        { Time.zone.local(2017, 6, 5, 12, 30)  }
      before { create(:leave_time, :annual, user: user, quota: 100, usable_hours: 100, effective_date: effective_date, expiration_date: expiration_date) }
      it 'can transition from approved to canceled unless LeaveApplication happened already' do
        leave_application = create(:leave_application, :personal, user: user, start_time: start_time, end_time: end_time).reload
        leave_application.approve!(create(:user, :hr))
        expect(leave_application.happened?).to be_truthy
        expect(leave_application.approved?).to be_truthy
        expect(leave_application.may_cancel?).to be_falsy
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

        context 'LeaveApplication on range boundary' do
          context 'LeaveApplication start_time is at the end of the range' do
            let(:start_time) { beginning - 5.days }
            let(:end_time)   { beginning }
            it 'should not be included in returned results' do
              expect(subject).not_to include(leave_application)
            end
          end

          context 'LeaveApplication end_time is at the start of the range' do
            let(:start_time) { closing }
            let(:end_time)   { closing + 5.days }
            it 'should not be included in returned results' do
              expect(subject).not_to include(leave_application)
            end
          end
        end
      end

      context 'LeaveApplication on range boundary' do
        context 'LeaveApplication start_time is at the end of the range' do
          let(:start_time) { beginning - 5.days }
          let(:end_time)   { beginning }
          it 'should not be included in returned results' do
            expect(subject).not_to include(leave_application)
          end
        end

        context 'LeaveApplication end_time is at the start of the range' do
          let(:start_time) { closing }
          let(:end_time)   { closing + 5.days }
          it 'should not be included in returned results' do
            expect(subject).not_to include(leave_application)
          end
        end
      end
    end

    describe '.personal' do
      let(:user) do
        User.skip_callback(:create, :after, :auto_assign_leave_time)
        create(:user, :hr)
      end
      let(:effective_date)  { Time.zone.local(2017, 5, 1).to_date }
      let(:expiration_date) { Time.zone.local(2017, 5, 31).to_date }
      let(:beginning)       { effective_date.beginning_of_day }
      let(:ending)          { expiration_date.end_of_day }
      let!(:leave_time)     { create(:leave_time, :annual, user: user, quota: 100, usable_hours: 100, effective_date: effective_date, expiration_date: expiration_date) }
      let!(:pending)        { create(:leave_application, :personal, user: user, start_time: Time.zone.local(2017, 5, 2, 9, 30), end_time: Time.zone.local(2017, 5, 4, 12, 30)) }
      let!(:approved)       { create(:leave_application, :personal, :approved, user: user, start_time: Time.zone.local(2017, 5, 9, 9, 30), end_time: Time.zone.local(2017, 5, 11, 12, 30)) }
      let!(:canceled)       { create(:leave_application, :personal, :canceled, user: user, start_time: Time.zone.local(2017, 5, 16, 9, 30), end_time: Time.zone.local(2017, 5, 18, 12, 30)) }
      let!(:rejected)       { create(:leave_application, :personal, :rejected, user: user, start_time: Time.zone.local(2017, 5, 23, 9, 30), end_time: Time.zone.local(2017, 5, 25, 12, 30)) }

      after { User.set_callback(:create, :after, :auto_assign_leave_time) }

      context 'default behaviour' do
        it 'should include only pending or approved applications' do
          personal = described_class.personal(user, beginning, ending)
          expect(personal.size).to eq 2
          expect(personal).to include(pending, approved)
          expect(personal).not_to include(canceled, rejected)
        end
      end

      context 'specific status of leave application' do
        it 'should only contain specific status of leave applications' do
          expect(described_class.personal(user, beginning, ending, [:approved])).to contain_exactly(approved)
          expect(described_class.personal(user, beginning, ending, [:canceled, :rejected])).to contain_exactly(canceled, rejected)
          expect(described_class.personal(user, beginning, ending, [:pending, :canceled])).to contain_exactly(pending, canceled)
        end
      end

      context 'overlaps on boundary' do
        it 'should not include other applications when overlaps on its\' start_time boundary' do
          expect(described_class.personal(user, pending.start_time - 1.day, pending.start_time)).not_to include(pending)
          expect(described_class.personal(user, approved.start_time - 1.day, approved.start_time)).not_to include(approved)
        end

        it 'should not include other applications when overlaps on its\' end_time boundary' do
          expect(described_class.personal(user, pending.end_time, pending.end_time + 1.day)).not_to include(pending)
          expect(described_class.personal(user, approved.end_time, approved.end_time + 1.day)).not_to include(approved)
        end
      end
    end
  end

  describe 'helper method' do
    describe '#special_type?' do
    end

    describe '#leave_time_params' do
    end
  end
end

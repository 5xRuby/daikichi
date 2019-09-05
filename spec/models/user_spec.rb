# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  let(:manager) { create(:user, :manager) }

  describe 'enum' do
    describe 'role' do
      it 'defines user role as enum' do
        # Choose a sample from User roles
        user = build(:user, role: User.roles.to_a.sample[0])
        user.valid?
        expect(user).to be_valid
      end

      it 'cannot save user role if not in the role enum list' do
        expect { build(:user, role: 'internship') }.to raise_error(ArgumentError)
        expect { build(:user, role: 'management') }.to raise_error(ArgumentError)
      end

      it 'can get options for select' do
        expect(described_class.enum_attributes_for_select(:roles)).to eq(I18n.t('activerecord.attributes.user.roles').map { |key, val| [val, key.to_s] })
      end

      it 'can get humanize enum value' do
        enum_key = described_class.roles.keys.sample
        expect(described_class.human_enum_value(:roles, enum_key)).to eq I18n.t("activerecord.attributes.user.roles.#{enum_key}")
      end
    end
  end

  describe '#associations' do
    it { is_expected.to have_many(:leave_times) }
    it { is_expected.to have_many(:leave_applications) }
    it { is_expected.to have_many(:bonus_leave_time_logs) }
  end

  describe '#validations' do
    subject { build(:user) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:login_name) }
    it { is_expected.to validate_uniqueness_of(:login_name).case_insensitive.scoped_to(:deleted_at) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:join_date) }

    context 'should validate that :email' do
      it 'is case-insensitively unique within the scope of :deleted_at' do
        email = Faker::Internet.email
        old_user = create(:user, email: email)
        user = build(:user, email: email)
        expect(user).to be_invalid
        expect(user.errors.messages[:email]).to include I18n.t('errors.messages.taken')
        old_user.destroy
        expect(user).to be_valid
      end
    end
  end

  describe '#callback' do
    context 'after_create' do
      describe '.auto_assign_leave_time' do
        it { is_expected.to callback(:auto_assign_leave_time).after(:create) }

        shared_examples 'different roles create LeaveTime with different leave_type' do |roles, leave_types|
          roles.each do |role|
            leave_types.each do |leave_type|
              it "should create LeaveTime with type :#{leave_type} when user is a/an #{role}" do
                result_leave_types = create(:user, role).leave_times.pluck(:leave_type).uniq
                expect(result_leave_types.size).to eq leave_types.size
                expect(result_leave_types).to include leave_type
              end
            end
          end
        end
        it_should_behave_like 'different roles create LeaveTime with different leave_type', %i(manager hr employee fulltime), %w(annual personal fullpaid_sick halfpaid_sick remote)
        it_should_behave_like 'different roles create LeaveTime with different leave_type', %i(intern),   %w(personal fullpaid_sick halfpaid_sick remote)
        it_should_behave_like 'different roles create LeaveTime with different leave_type', %i(contractor), %w(personal)

        shared_examples 'specific roles should not create any LeaveTime' do |roles|
          roles.each do |role|
            it "should not create any LeaveTime when user is on the state of #{role}" do
              expect(create(:user, role).leave_times.any?).to be_falsey
            end
          end
        end
        it_should_behave_like 'specific roles should not create any LeaveTime', %i(pending resigned)

        shared_examples 'leave_type created with specific quota' do |roles, leave_type, quota|
          roles.each do |role|
            it "should have leave_type of \"#{leave_type}\" with quota of #{quota} in roles: #{roles.join ', '}" do
              leave_time = create(:user, role).leave_times.find_by(leave_type: leave_type)
              expect(leave_time).not_to be_nil
              expect(leave_time.quota).to be quota
              expect(leave_time.usable_hours).to be quota
            end
          end
        end
        all_roles = %i(manager hr employee intern)
        it_should_behave_like 'leave_type created with specific quota', all_roles, 'personal',      112
        it_should_behave_like 'leave_type created with specific quota', all_roles, 'remote',        8
        it_should_behave_like 'leave_type created with specific quota', all_roles, 'fullpaid_sick', 56
        it_should_behave_like 'leave_type created with specific quota', all_roles, 'halfpaid_sick', 184

        it 'should not create any LeaveTime of the user if not specified assign_leave_time and assign_date' do
          user = create(:user, :without_assign_date)
          expect(user.leave_times.any?).to be_falsey
        end

        it 'should create LeaveTime of the user if specified assign_leave_time and assign_date' do
          user = create(:user, :fulltime)
          expect(user.leave_times.any?).to be_truthy
        end

        it 'should have error message when assign_leave_time is true while assign_date is nil' do
          user = described_class.new(attributes_for(:user, :hr))
          user.assign_leave_time = '1'
          expect(user.valid?).to be_falsey
          expect(user.errors.keys).to include :assign_date
          expect(user.errors[:assign_date]).to include I18n.t('activerecord.errors.models.user.attributes.assign_date.blank')
        end
      end
    end
  end

  describe '.scope' do
    describe '.filter_by_join_date' do
      let!(:fulltime) { create(:user, :fulltime, join_date: Date.current - 2.years) }
      let!(:parttime) { create(:user, :parttime, join_date: Date.current - 1.year) }
      subject { User.filter_by_join_date(Date.current.month, Date.current.day) }

      before do
        create(:user, :fulltime, join_date: Date.current - 3.days)
      end

      it 'should get all users that join_date match with given month and day' do
        expect(subject.size).to eq 2
        expect(subject).to include fulltime
        expect(subject).to include parttime
      end
    end

    describe '.valid' do
      subject { described_class.valid }
      let!(:resigned) { create(:user, role: :resigned) }
      let!(:pending)  { create(:user, role: :pending) }
      let!(:fulltime) { create(:user, :fulltime) }
      let!(:parttime) { create(:user, :parttime) }
      let!(:future_employee) { create(:user, join_date: Date.current + 1.day) }

      it 'should include all users except resigned and pending users' do
        expect(subject).to include fulltime
        expect(subject).to include parttime
        expect(subject).not_to include resigned
        expect(subject).not_to include pending
      end

      it 'should not include users whose join_date is after current date' do
        expect(subject.reload).not_to include future_employee
      end
    end

    describe '.fulltime' do
      subject { described_class.fulltime }
      let(:fulltime) { create(:user, :fulltime) }
      let(:parttime) { create(:user, :parttime) }
      let(:future_fulltime) { create(:user, :fulltime, join_date: Date.current + 1.day) }

      it 'should include active fulltime user only' do
        expect(subject).to include fulltime
        expect(subject).not_to include parttime
        expect(subject).not_to include future_fulltime
      end
    end

    describe '.parttime' do
      subject { described_class.parttime }
      let!(:fulltime) { create(:user, :fulltime) }
      let!(:parttime) { create(:user, :parttime) }
      let!(:future_parttime) { create(:user, :parttime, join_date: Date.current + 1.day) }

      it 'should include active parttime user only' do
        expect(subject).to include parttime
        expect(subject).not_to include fulltime
        expect(subject).not_to include future_parttime
      end
    end
  end

  describe '#seniority' do
    let(:base_date) { Date.current }
    subject { user.seniority(base_date) }

    context 'parttime user' do
      let(:user) { build(:user, :parttime, join_date: Date.current - 2.years) }

      it { expect(subject).to eq 0 }
    end

    context 'fulltime user' do
      let(:user) { build(:user, :fulltime, join_date: join_date) }

      context 'joined less than a year' do
        let(:join_date) { Date.current - 1.year + 1.day }
        it { expect(subject).to eq 0 }
      end

      context 'on first joined anniversary' do
        let(:join_date) { Date.current - 1.year }
        it { expect(subject).to eq 1 }
      end

      context 'a comparison date (2 years after join date) specified' do
        let(:join_date) { Date.current - 2.years + 5.days }
        let(:base_date) { Date.current + 5.days }

        it { expect(subject).to eq 2 }
      end
    end
  end

  describe '#fulltime?' do
    subject { user.fulltime? }
    context 'parttime user' do
      let(:user) { create(:user, :parttime) }

      it { expect(subject).to be_falsey }
    end

    context 'fulltime user' do
      let(:user) { create(:user, :fulltime) }

      it { expect(subject).to be_truthy }
    end
  end

  describe '#this_year_join_anniversary' do
    let(:user) { create(:user, :fulltime, join_date: join_date) }
    subject { user.this_year_join_anniversary }

    context "this year's join anniversary not passed" do
      let(:join_date) { Date.current - 1.year + 1.day }
      it { expect(subject).to eq Date.current + 1.day }
    end

    context 'today is join_anniversary' do
      let(:join_date) { Date.current - 2.years }
      it { expect(subject).to eq Date.current }
    end

    context "this year's join anniversary passed" do
      let(:join_date) { Date.current - 3.years - 1.day }
      it { expect(subject).to eq Date.current - 1.day }
    end
  end

  describe '#next_join_anniversary' do
    let(:user) { create(:user, :fulltime, join_date: join_date) }
    subject { user.next_join_anniversary }

    context "this year's join anniversary not passed" do
      let(:join_date) { Date.current - 1.year + 1.day }
      it { expect(subject).to eq Date.current + 1.day }
    end

    context 'today is join_anniversary' do
      let(:join_date) { Date.current - 1.year }
      it { expect(subject).to eq Date.current }
    end

    context "this year's join anniversary passed" do
      let(:join_date) { Date.current - 2.years - 1.day }
      it { expect(subject).to eq Date.current + 1.year - 1.day }
    end
  end

  describe '#is_{role}?' do
    let(:employee) { create(:user, :employee) }
    let(:manager)  { create(:user, :manager) }
    let(:hr)       { create(:user, :hr) }

    context 'is_manager?' do
      it 'is true if user is manager' do
        expect(manager.is_manager?).to be_truthy
      end

      it 'is false if user is not manager' do
        expect(hr.is_manager?).to be_falsey
        expect(employee.is_manager?).to be_falsey
      end
    end

    context 'is_hr?' do
      it 'is true if user is hr' do
        expect(hr.is_hr?).to be_truthy
      end

      it 'is false if user is not hr' do
        expect(employee.is_hr?).to be_falsey
        expect(manager.is_hr?).to be_falsey
      end
    end

    describe 'assign_leave_time?' do
      let(:user) { described_class.new(attributes_for(:user, :fulltime)) }

      it 'is true if assign_leave_time is string value of "1"' do
        user.assign_leave_time = '1'
        expect(user.assign_leave_time?).to be_truthy
      end

      it 'is false if assign_leave_time is string value of "0"' do
        user.assign_leave_time = '0'
        expect(user.assign_leave_time?).to be_falsey
      end
    end
  end
end

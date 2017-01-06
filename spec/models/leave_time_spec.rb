# frozen_string_literal: true
require "rails_helper"

RSpec.describe LeaveTime, type: :model do
  let(:first_year_employee) { FactoryGirl.create(:first_year_employee) }
  let(:third_year_employee) { FactoryGirl.create(:third_year_employee) }
  let(:senior_employee) { FactoryGirl.create(:user, :employee, join_date: 30.years.ago) }
  let(:contractor)      { FactoryGirl.create(:user, :contractor) }

  describe "#validations" do
    subject { described_class.new(params) }

    context "user" do
      let(:params) { { user: nil } }
      it "is invalid without user association" do
        expect(subject.valid?).to be_falsey
        expect(subject.errors.messages[:user]).to include I18n.t("activerecord.errors.models.leave_time.attributes.user.required")
      end
    end

    context "leave_type" do
      let(:params) { { leave_type: nil } }
      it "is invalid without :leave_type" do
        expect(subject.valid?).to be_falsey
        expect(subject.errors.messages[:leave_type]).to include I18n.t("errors.messages.blank")
      end
    end

    context "effective_date" do
      let(:params) { { effective_date: nil } }
      it "is invalid without :effective_date" do
        expect(subject.valid?).to be_falsey
        expect(subject.errors.messages[:effective_date]).to include I18n.t("errors.messages.blank")
      end
    end

    context "expiration_date" do
      let(:params) { { expiration_date: nil } }
      it "is invalid without :expiration_date" do
        expect(subject.valid?).to be_falsey
        expect(subject.errors.messages[:expiration_date]).to include I18n.t("errors.messages.blank")
      end
    end

    context "range" do
      context "expiration_date earlier than effective_date" do
        let(:params) {
          FactoryGirl.attributes_for(:leave_time,
            effective_date:  Time.current.strftime('%Y-%m-%d'),
            expiration_date: (Time.current - 1.day).strftime('%Y-%m-%d')) }
        it "is invalid" do
          expect(subject.valid?).to be_falsey
          expect(subject.errors.messages[:effective_date]). to include I18n.t("activerecord.errors.models.leave_time.attributes.effective_date.range_should_be_positive")
        end
      end

      context "overlaps" do
        let!(:leave_time) {
          FactoryGirl.create(:leave_time, :annual,
            effective_date:   Time.current.strftime('%Y-%m-%d'),
            expiration_date: (Time.current + 3.day).strftime('%Y-%m-%d')) }

        context "with owned records" do
          context "same leave_type" do
            let(:params) {
              FactoryGirl.attributes_for(:leave_time, :annual,
                effective_date:  (Time.current + 2.day).strftime('%Y-%m-%d'),
                expiration_date: (Time.current + 4.day).strftime('%Y-%m-%d'),
                user_id: leave_time.user_id) }
            it "is invalid" do
              expect(subject.valid?).to be_falsey
              expect(subject.errors.messages[:effective_date]).to include I18n.t("activerecord.errors.models.leave_time.attributes.effective_date.range_should_not_overlaps")
            end
          end

          context "different leave_type" do
            let(:params) {
              FactoryGirl.attributes_for(:leave_time, :personal,
                effective_date:  (Time.current + 2.day).strftime('%Y-%m-%d'),
                expiration_date: (Time.current + 4.day).strftime('%Y-%m-%d'),
                user: leave_time.user) }
            it "is valid" do
              expect(subject.valid?).to be_falsey
              expect(subject.errors.messages[:effective_date]).not_to include I18n.t("activerecord.errors.models.leave_time.attributes.effective_date.range_should_not_overlaps")
            end
          end
        end

        context "with others users' records" do
          let(:params) {
            FactoryGirl.attributes_for(:leave_time, :personal,
              effective_date:  (Time.current + 2.day).strftime('%Y-%m-%d'),
              expiration_date: (Time.current + 4.day).strftime('%Y-%m-%d')) }
          it "is valid" do
            expect(subject.valid?).to be_falsey
            expect(subject.errors.messages[:effective_date]).not_to include I18n.t("activerecord.errors.models.leave_time.attributes.effective_date.range_should_not_overlaps")
          end
        end
      end
    end
  end

  describe ".scope" do
    let(:beginning) { Time.current }
    let(:ending)    { (Time.current + 1.year) }
    let(:effective_date)  { beginning - 10.days }
    let(:expiration_date) { beginning + 15.days }
    let!(:leave_time) { FactoryGirl.create(:leave_time, :annual, effective_date: effective_date, expiration_date: expiration_date) }
    describe ".overlaps" do
      subject { described_class.overlaps(beginning, ending) }

      context "partially overlaps" do
        it "is include in returned results" do
          expect(subject).to include leave_time
        end
      end

      context "totally overlaps" do
        let(:effective_date)  { beginning }
        let(:expiration_date) { ending }
        it "is include in returned results" do
          expect(subject).to include leave_time
        end
      end

      context "not overlaps at all" do
        context "before given range" do
          let(:effective_date)  { beginning - 10.days }
          let(:expiration_date) { beginning - 5.days }
          it "is not include in returned results" do
            expect(subject).not_to include leave_time
          end
        end

        context "after given range" do
          let(:effective_date)  { ending + 5.days }
          let(:expiration_date) { ending + 10.days }
          it "is not include in returned results" do
            expect(subject).not_to include leave_time
          end
        end
      end
    end

    describe ".effective" do
      context "no specific date given" do
        subject { described_class.effective }

        context "records overlaps with given date" do
          let(:effective_date)  { Time.now - 3.days }
          let(:expiration_date) { Time.now }
          it "is include in returned results" do
            expect(subject).to include leave_time
          end
        end

        context "records not overlaps with give date" do
          let(:effective_date)  { beginning - 3.days }
          let(:expiration_date) { beginning - 1.days }
          it "is not include in returned results" do
            expect(subject).not_to include leave_time
          end
        end
      end

      context "a specific date given" do
        let(:base_date) { (Time.current + 2.days) }
        subject { described_class.effective(base_date) }

        context "records overlaps with given date" do
          let(:effective_date)  { base_date - 2.days }
          let(:expiration_date) { base_date }
          it "is include in returned results" do
            expect(subject).to include leave_time
          end
        end

        context "records not overlaps with given date" do
          let(:effective_date)  { base_date + 1.days }
          let(:expiration_date) { base_date + 2.days }
          it "is not include in returned results" do
            expect(subject).not_to include leave_time
          end
        end
      end
    end
  end

  describe "init_quota" do
    shared_examples "annual_leave" do 
      it "third year employee should have 80 hours" do
        annual = FactoryGirl.create(:leave_time, :annual, user: third_year_employee)
        annual.init_quota
        expect(annual.quota).to eq 80
      end

      it "employee with 3-year employee tenure should have 112 hours" do
        annual = FactoryGirl.create(:leave_time, :annual, user: FactoryGirl.build(:employee, join_date: 3.years.ago))
        annual.init_quota
        expect(annual.quota).to eq 112
      end

      it "employee with 4-year employee tenure should have 112 hours" do
        annual = FactoryGirl.create(:leave_time, :annual, user: FactoryGirl.build(:employee, join_date: 4.years.ago))
        annual.init_quota
        expect(annual.quota).to eq 112
      end

      it "employee with 5-year employee tenure should have 120 hours" do
        annual = FactoryGirl.create(:leave_time, :annual, user: FactoryGirl.build(:employee, join_date: 5.years.ago))
        annual.init_quota
        expect(annual.quota).to eq 120
      end

      it "employee with 9-year employee tenure should have 120 hours" do
        annual = FactoryGirl.create(:leave_time, :annual, user: FactoryGirl.build(:employee, join_date: 9.years.ago))
        annual.init_quota
        expect(annual.quota).to eq 120
      end

      context "employee with more than 10-year employee tenure should have extra 8 hours for each additional year" do
        it "employee with 10-year employee tenure should have 128 hours" do
          annual = FactoryGirl.create(:leave_time, :annual, user: FactoryGirl.build(:employee, join_date: 10.years.ago))
          annual.init_quota
          expect(annual.quota).to eq 128
        end

        it "employee with 11-year employee tenure should have 136 hours" do
          annual = FactoryGirl.create(:leave_time, :annual, user: FactoryGirl.build(:employee, join_date: 11.years.ago))
          annual.init_quota
          expect(annual.quota).to eq 136
        end

        it "employee with 23-year employee tenure should have 232 hours" do
          annual = FactoryGirl.create(:leave_time, :annual, user: FactoryGirl.build(:employee, join_date: 23.years.ago))
          annual.init_quota
          expect(annual.quota).to eq 232
        end
      end

      it "senior employee should have no more than 240 hours" do
        annual = FactoryGirl.create(:leave_time, :annual, user: senior_employee)
        annual.init_quota
        expect(annual.quota).to eq 240
      end

      it "non-employee have no leave time" do
        annual = FactoryGirl.create(:leave_time, :annual, user: contractor)
        expect(annual.init_quota).to be_falsey
      end
    end

    context "new employees have annual leave" do
      it_behaves_like "annual_leave"
      it "first year employee should have 56 hours" do
        annual = FactoryGirl.create(:leave_time, :annual, user: first_year_employee)
        annual.init_quota
        expect(annual.quota).to eq 56 
      end
    end

    context "new employees have no annual leave" do 
      before { stub_const("LeaveTime::LEAVE_FOR_NEW_EMPLOYEES", false) }
      it_behaves_like "annual_leave"
      it "first year employee should have no annual leave" do
        annual = FactoryGirl.create(:leave_time, :annual, user: first_year_employee)
        annual.init_quota
        expect(annual.quota).to eq 0 
      end
    end

    context "sick leave" do
      it "first year employee should have 240 hours (30 days)" do
        #FIXME: Test will failed when encountered leap year
        sick = FactoryGirl.create(:leave_time, :sick, user: first_year_employee)
        sick.init_quota
        expect(sick.quota).to eq 240
      end

      it "regular employee should have 240 hours" do
        sick = FactoryGirl.create(:leave_time, :sick, user: senior_employee)
        sick.init_quota
        expect(sick.quota).to eq 240
      end

      it "non-employee have no leave time" do
        sick = FactoryGirl.create(:leave_time, :sick, user: contractor)
        expect(sick.init_quota).to be_falsey
      end
    end

    context "personal leave" do
      it "first year employee should have 56 hours (7 days)" do
        personal = FactoryGirl.create(:leave_time, :personal, user: first_year_employee)
        personal.init_quota
        expect(personal.quota).to eq 56
      end

      it "regular employee should have 56 hours" do
        personal = FactoryGirl.create(:leave_time, :personal, user: senior_employee)
        personal.init_quota
        expect(personal.quota).to eq 56
      end

      it "non-employee have no leave time" do
        personal = FactoryGirl.create(:leave_time, :personal, user: contractor)
        expect(personal.init_quota).to be_falsey
      end
    end

    context "bonus leave" do
      it "initial bonus leave time is 0" do
        bonus = FactoryGirl.create(:leave_time, :bonus, user: senior_employee)
        bonus.init_quota
        expect(bonus.quota).to eq 0
      end

      it "non-employee have no leave time" do
        bonus = FactoryGirl.create(:leave_time, :bonus, user: contractor)
        expect(bonus.init_quota).to be_falsey
      end
    end
  end
end

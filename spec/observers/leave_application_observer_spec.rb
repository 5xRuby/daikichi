# frozen_string_literal: true
require 'rails_helper'
RSpec.describe LeaveApplicationObserver do
  let(:user)              { create(:user, :hr) }
  let(:effective_date)    { Time.zone.local(2017, 5, 2) }
  let(:expiration_date)   { Time.zone.local(2017, 5, 30) }
  let(:start_time)        { Time.zone.local(2017, 5, 2, 9, 30) }
  let(:end_time)          { Time.zone.local(2017, 5, 5, 10, 30) }
  let(:total_leave_hours) { Daikichi::Config::Biz.within(start_time, end_time).in_hours }
  let(:leave_application) { create(:leave_application, :personal, user: user, start_time: start_time, end_time: end_time) }

  before { User.skip_callback(:create, :after, :auto_assign_leave_time) }
  after  { User.set_callback(:create, :after, :auto_assign_leave_time)  }

  describe '.create_leave_time_usages' do
    let!(:leave_time) { create(:leave_time, :annual, user: user, quota: total_leave_hours, usable_hours: total_leave_hours, effective_date: effective_date, expiration_date: expiration_date) }
    context 'after_create' do
      it 'should successfully create LeaveTimeUsage on sufficient LeaveTime hours' do
        leave_time_usage = leave_application.leave_time_usages.first
        total_used_hours = leave_application.leave_time_usages.map(&:used_hours).sum
        leave_time.reload
        expect(total_used_hours).to eq total_leave_hours
        expect(leave_time_usage.leave_time).to eq leave_time
        expect(leave_time.locked_hours).to eq total_leave_hours
      end

      it 'should not create LeaveTimeUsage when insufficient LeaveTime hours' do
        la = create(:leave_application, :personal, user: user, start_time: start_time, end_time: end_time + 1.hour)
        expect(la.errors.any?).to be_truthy
        expect(la.leave_time_usages.any?).to be false
        expect(leave_time.usable_hours).to eq total_leave_hours
      end
    end

    context 'after_update' do
      it 'should recreate LeaveTimeUsage only when AASM event is "revise"' do
        la = create(:leave_application, :personal, :approved, user: user, start_time: start_time, end_time: end_time)
        leave_time_usage = la.leave_time_usages.first
        total_used_hours = la.leave_time_usages.map(&:used_hours).sum
        leave_time.reload
        expect(total_used_hours).to eq total_leave_hours
        expect(leave_time_usage.leave_time).to eq leave_time
        expect(leave_time.used_hours).to eq total_leave_hours

        la.assign_attributes(start_time: start_time + 1.hour)
        la.revise!
        leave_time_usage = la.leave_time_usages.first
        leave_time.reload
        total_used_hours = la.leave_time_usages.map(&:used_hours).sum
        expect(total_used_hours).to eq(total_leave_hours - 1)
        expect(leave_time_usage.leave_time).to eq leave_time
        expect(leave_time.locked_hours).to eq(total_leave_hours - 1)
      end
    end
  end

  describe '.hours_update' do
    let(:quota) { 100 }
    let!(:leave_time) { create(:leave_time, :annual, user: user, quota: quota, usable_hours: quota, effective_date: effective_date, expiration_date: expiration_date) }
    context 'before_update' do
      describe 'AASM "approve" event' do
        it 'should transfer locked_hours to used_hours' do
          leave_time_usage = leave_application.leave_time_usages.first
          leave_time.reload
          expect(leave_time_usage.leave_time).to eq leave_time
          expect(leave_time.usable_hours).to eq(quota - total_leave_hours)
          expect(leave_time.locked_hours).to eq total_leave_hours
          leave_application.reload.approve! user
          leave_time.reload
          expect(leave_time.usable_hours).to eq(quota - total_leave_hours)
          expect(leave_time.used_hours).to eq total_leave_hours
        end
      end

      shared_examples 'return locked_hours back to usable_hours' do |event, required_user|
        describe "AASM \"#{event}\" event" do
          it "should return locked_hours back to usable_hours when pending to #{event}ed" do
            leave_time_usage = leave_application.leave_time_usages.first
            leave_time.reload
            expect(leave_time_usage.leave_time).to eq leave_time
            expect(leave_time.usable_hours).to eq(quota - total_leave_hours)
            expect(leave_time.locked_hours).to eq total_leave_hours
            leave_application.reload.send :"#{event}!", (required_user ? user : nil)
            leave_time.reload
            expect(leave_time.usable_hours).to eq quota
            expect(leave_time.locked_hours).to be_zero
          end
        end
      end

      describe 'AASM "reject" event' do
        it_should_behave_like 'return locked_hours back to usable_hours', :reject, true

        it 'should return used_hours back to usable_hours when approved to rejected' do
          leave_application.reload.approve! user
          leave_time.reload
          expect(leave_time.usable_hours).to eq(quota - total_leave_hours)
          expect(leave_time.used_hours).to eq total_leave_hours
          expect(leave_time.locked_hours).to be_zero
          leave_application.reload.reject! user
          leave_time.reload
          expect(leave_time.usable_hours).to eq quota
          expect(leave_time.used_hours).to be_zero
          expect(leave_time.locked_hours).to be_zero
          expect(leave_application.leave_time_usages).to be_empty
        end
      end

      describe 'AASM "cancel" event' do
        it_should_behave_like 'return locked_hours back to usable_hours', :cancel
      end

      describe 'AASM "revise" event' do
        shared_examples 'revise attribute' do |attribute, value|
          it "should successfully recreate LeaveTimeUsage when application #{attribute} changed" do
            leave_application.assign_attributes(attribute => value)
            leave_application.revise!
            leave_application.reload
            used_hours = Daikichi::Config::Biz.within(leave_application.start_time, leave_application.end_time).in_hours
            leave_time_usage = leave_application.leave_time_usages.first
            total_used_hours = leave_application.leave_time_usages.map(&:used_hours).sum
            leave_time.reload
            expect(leave_application.hours).to eq used_hours
            expect(leave_application.status).to eq 'pending'
            expect(total_used_hours).to eq used_hours
            expect(leave_time_usage.leave_time).to eq leave_time
            expect(leave_time.usable_hours).to eq quota - used_hours
            expect(leave_time.locked_hours).to eq used_hours
          end
        end

        context 'pending application' do
          let!(:leave_application) { create(:leave_application, :personal, user: user, start_time: start_time, end_time: end_time) }
          it_should_behave_like 'revise attribute', :start_time,  Time.zone.local(2017, 5, 3, 9, 30)
          it_should_behave_like 'revise attribute', :end_time,    Time.zone.local(2017, 5, 3, 12, 30)
          it_should_behave_like 'revise attribute', :description, Faker::Lorem.paragraph
        end

        context 'approved application' do
          let!(:leave_application) do
            create(:leave_application, :personal, user: user, start_time: start_time, end_time: end_time)
            user.leave_applications.first.approve! user
            user.leave_applications.first
          end
          it_should_behave_like 'revise attribute', :start_time,  Time.zone.local(2017, 5, 3, 9, 30)
          it_should_behave_like 'revise attribute', :end_time,    Time.zone.local(2017, 5, 3, 12, 30)
          it_should_behave_like 'revise attribute', :description, Faker::Lorem.paragraph
        end
      end
    end
  end
end

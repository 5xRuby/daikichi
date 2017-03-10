# frozen_string_literal: true
require 'rails_helper'

describe LeaveTimeBuilder do
  let(:user) { FactoryGirl.create(:user) }
  let(:monthly_leave_types) { Settings.leave_types.to_a.select { |lt| lt.second['creation'] == 'monthly' } }
  let(:join_date_based_leave_types) { Settings.leave_types.to_a.select { |lt| lt.second['creation'] == 'join_date_based' } }
  let(:seniority_based_leave_types) do
     join_date_based_leave_types.select do |lt|
       !(lt.second.dig('quota').is_a? Integer) && lt.second.dig('quota', 'type') == 'seniority_based'
     end
   end

  describe '.automatically_import' do
    before do
      LeaveTimeBuilder.new(user).automatically_import
    end

    context 'fulltime employee' do
      let(:user) { FactoryGirl.create(:user, :fulltime) }

      it 'should run both monthly and join date based import without prebuild settings' do
        leave_times = user.leave_times.reload
        expect(leave_times.size).to eq monthly_leave_types.size + join_date_based_leave_types.size
        monthly_leave_time = leave_times.find { |x| x.leave_type == monthly_leave_types.first.first }
        expect(monthly_leave_time.effective_date).to  eq Time.zone.today
        expect(monthly_leave_time.expiration_date).to eq Time.zone.today.end_of_month
      end
    end

    context 'partime employee' do
      let(:user) { FactoryGirl.create(:user, :parttime) }

      it 'should run both monthly and join date based import without prebuild settings and should not get seniority_based leave_times' do
        leave_times = user.leave_times.reload
        expect(leave_times.size).to eq monthly_leave_types.size + join_date_based_leave_types.size - seniority_based_leave_types.size
        monthly_leave_time = leave_times.find { |x| x.leave_type == monthly_leave_types.first.first }
        expect(monthly_leave_time.effective_date).to  eq Time.zone.today
        expect(monthly_leave_time.expiration_date).to eq Time.zone.today.end_of_month
      end
    end
  end

  describe '.join_date_based_import' do
    before do
      LeaveTimeBuilder.new(user).join_date_based_import
    end

    context 'fulltime employee' do
      let(:user) { FactoryGirl.create(:user, :fulltime) }

      it 'should get seniority_based leave_times' do
        leave_times = user.leave_times.reload
        expect(leave_times.size).to eq join_date_based_leave_types.size
        config = seniority_based_leave_types.first.second
        initial_quota = if user.seniority >= config['quota']['maximum_seniority']
                          config['quota']['maximum_quota']
                        else
                          config['quota']['values'][user.seniority.to_s.to_sym] * 8
                        end
        seniority_based_leave_time = leave_times.find { |x| x.leave_type == seniority_based_leave_types.first.first }
        expect(seniority_based_leave_time.quota).to eq initial_quota
        expect(seniority_based_leave_time.usable_hours).to eq initial_quota
        expect(seniority_based_leave_time.used_hours).to eq 0
        expect(seniority_based_leave_time.effective_date).to  eq user.next_join_anniversary
        expect(seniority_based_leave_time.expiration_date).to eq user.next_join_anniversary + 1.year - 1.day
      end
    end

    context 'parttime employee' do
      let(:user) { FactoryGirl.create(:user, :parttime) }

      it 'should not get seniority_based leave_times' do
        leave_times = user.leave_times.reload
        expect(leave_times.size).to eq join_date_based_leave_types.size - seniority_based_leave_types.size
        leave_time = leave_times.first
        initial_quota = join_date_based_leave_types.select { |lt| lt.first == leave_time.leave_type }.first.second['quota']
        expect(leave_time.quota).to eq initial_quota
        expect(leave_time.usable_hours).to eq initial_quota
        expect(leave_time.used_hours).to eq 0
        expect(leave_time.effective_date).to  eq user.next_join_anniversary
        expect(leave_time.expiration_date).to eq user.next_join_anniversary + 1.year - 1.day
      end
    end
  end

  describe '.monthly_import' do
    context 'prebuild' do
      before do
        LeaveTimeBuilder.new(user).monthly_import(prebuild: true)
      end

      it 'is build for the comming month' do
        leave_times = user.leave_times.reload
        expect(leave_times.size).to eq monthly_leave_types.size
        leave_time = leave_times.first
        initial_quota = monthly_leave_types.select { |lt| lt.first == leave_time.leave_type }.first.second['quota']
        expect(leave_time.quota).to eq initial_quota
        expect(leave_time.usable_hours).to eq initial_quota
        expect(leave_time.used_hours).to eq 0
        expect(leave_time.effective_date).to  eq Time.zone.today.next_month.beginning_of_month
        expect(leave_time.expiration_date).to eq Time.zone.today.next_month.end_of_month
      end
    end

    context 'not prebuild' do
      before do
        LeaveTimeBuilder.new(user).monthly_import
      end

      it 'is build for current month' do
        leave_times = user.leave_times.reload
        expect(leave_times.size).to eq monthly_leave_types.size
        leave_time = leave_times.first
        initial_quota = monthly_leave_types.select { |lt| lt.first == leave_time.leave_type }.first.second['quota']
        expect(leave_time.quota).to eq initial_quota
        expect(leave_time.usable_hours).to eq initial_quota
        expect(leave_time.used_hours).to eq 0
        expect(leave_time.effective_date).to  eq Time.zone.today
        expect(leave_time.expiration_date).to eq Time.zone.today.end_of_month
      end
    end
  end
end

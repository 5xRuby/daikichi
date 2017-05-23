# frozen_string_literal: true
require 'rails_helper'

describe LeaveTimeBatchBuilder do
  let(:monthly_lead_days) { Settings.leed_days.monthly }
  let(:join_date_based_leed_days)   { Settings.leed_days.join_date_based }
  let(:monthly_leave_types)         { Settings.leave_types.to_a.select { |lt| lt.second['creation'] == 'monthly' } }
  let(:join_date_based_leave_types) { Settings.leave_types.to_a.select { |lt| lt.second['creation'] == 'join_date_based' } }
  let(:seniority_based_leave_types) do
     join_date_based_leave_types.select do |lt|
       !(lt.second.dig('quota').is_a? Integer) && lt.second.dig('quota', 'type') == 'seniority_based'
     end
   end

  describe 'automatically_import' do
    before { User.skip_callback(:create, :after, :auto_assign_leave_time) }
    after  { User.set_callback(:create, :after, :auto_assign_leave_time)  }

    context 'is forced' do
      let!(:fulltime) { FactoryGirl.create(:user, :fulltime, join_date: Date.current) }
      let!(:parttime) { FactoryGirl.create(:user, :parttime, join_date: Date.current) }
      let!(:user)     { FactoryGirl.create(:user, join_date: Date.current) }

      before do
        described_class.new(forced: true).automatically_import
      end

      it 'should run join_date_based_import and monthly import with prebuild option for all users' do
        leave_times = LeaveTime.where(user_id: [fulltime.id, parttime.id, user.id])
        expect(leave_times.reload.size).to eq((monthly_leave_types.size + join_date_based_leave_types.size) * 3 - seniority_based_leave_types.size)
        monthly_leave_time = leave_times.find { |x| x.leave_type == monthly_leave_types.first.first }
        expect(monthly_leave_time.effective_date).to  eq Time.zone.today
        expect(monthly_leave_time.expiration_date).to eq Time.zone.today.end_of_month

        join_date_based_leave_time = leave_times.find { |x| x.leave_type == join_date_based_leave_types.first.first }
        join_anniversary = user.next_join_anniversary
        expect(join_date_based_leave_time.effective_date).to  eq join_anniversary
        expect(join_date_based_leave_time.expiration_date).to eq join_anniversary + 1.year - 1.day
      end
    end

    context 'not forced' do
      let!(:fulltime) { FactoryGirl.create(:user, :fulltime, join_date: join_date) }
      let!(:parttime) { FactoryGirl.create(:user, :parttime, join_date: join_date) }
      let!(:user)     { FactoryGirl.create(:user, join_date: join_date - 1.day) }

      context 'end of working month' do
        let(:join_date) { $biz.time(monthly_lead_days, :days).before($biz.periods.before(Time.current.end_of_month).first.end_time) - 2.years + join_date_based_leed_days.days }

        before do
          Timecop.freeze($biz.time(monthly_lead_days, :days).before($biz.periods.before(Time.current.end_of_month).first.end_time))
          described_class.new.automatically_import
        end
        after { Timecop.return }

        it 'should run join date based import only for users that join_date anniversary is comming and monthly import without prebuild option for all users' do
          leave_times = LeaveTime.where(user_id: [fulltime.id, parttime.id, user.id])
          expect(leave_times.reload.size).to eq(monthly_leave_types.size * 3 + join_date_based_leave_types.size * 2 - seniority_based_leave_types.size)

          join_date_based_leave_time = leave_times.find { |x| x.leave_type == join_date_based_leave_types.first.first }
          join_anniversary = fulltime.next_join_anniversary
          expect(join_date_based_leave_time.effective_date).to  eq join_anniversary
          expect(join_date_based_leave_time.expiration_date).to eq join_anniversary + 1.year - 1.day
        end
      end

      context 'not end of working month' do
        let(:join_date) { Date.current.end_of_month + 3.days - 2.years + join_date_based_leed_days.days }

        before do
          Timecop.freeze(Date.current.end_of_month + 3.days)
          described_class.new.automatically_import
        end
        after { Timecop.return }

        it 'should run join date based import for users that join_date anniversary is comming only' do
          leave_times = LeaveTime.where(user_id: [fulltime.id, parttime.id, user.id])
          expect(leave_times.reload.size).to eq(join_date_based_leave_types.size * 2 - seniority_based_leave_types.size)

          join_date_based_leave_time = leave_times.find { |x| x.leave_type == join_date_based_leave_types.first.first }
          join_anniversary = fulltime.next_join_anniversary
          expect(join_date_based_leave_time.effective_date).to  eq join_anniversary
          expect(join_date_based_leave_time.expiration_date).to eq join_anniversary + 1.year - 1.day
        end
      end
    end
  end
end

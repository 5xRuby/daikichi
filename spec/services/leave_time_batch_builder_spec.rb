# frozen_string_literal: true

require 'rails_helper'

describe LeaveTimeBatchBuilder do
  let(:monthly_lead_days) { Settings.leed_days.monthly }
  let(:join_date_based_leed_days) { Settings.leed_days.join_date_based }
  let(:monthly_leave_types) { Settings.leave_types.to_a.select { |lt| lt.second['creation'] == 'monthly' } }
  let(:weekly_leave_types) { Settings.leave_types.to_a.select { |lt| lt.second['creation'] == 'weekly' } }
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
      let!(:fulltime) { FactoryBot.create(:user, :fulltime, join_date: Date.current - 1.year - 1.day) }
      let!(:parttime) { FactoryBot.create(:user, :intern, join_date: Date.current - 1.year - 1.day) }
      let!(:contractor) { FactoryBot.create(:user, :contractor, join_date: Date.current - 1.year - 1.day) }
      let!(:user) { FactoryBot.create(:user, join_date: Date.current - 1.year - 1.day) }

      before do
        described_class.new(forced: true).automatically_import
      end

      it 'should run join_date_based_import and monthly import with prebuild option for all users' do
        unless monthly_leave_types.blank?
          leave_times = LeaveTime.where(user_id: [fulltime.id, parttime.id, user.id, contractor.id])
          expect(leave_times.reload.size).to eq(1 + (monthly_leave_types.size + join_date_based_leave_types.size) * 3 - seniority_based_leave_types.size)
          monthly_leave_time = leave_times.find { |x| x.leave_type == monthly_leave_types.first.first }
          expect(monthly_leave_time.effective_date).to  eq Time.zone.today
          expect(monthly_leave_time.expiration_date).to eq Time.zone.today.end_of_month

          join_date_based_leave_time = leave_times.find { |x| x.leave_type == join_date_based_leave_types.first.first }
          join_anniversary = user.next_join_anniversary
          expect(join_date_based_leave_time.effective_date).to  eq join_anniversary
          expect(join_date_based_leave_time.expiration_date).to eq join_anniversary + 1.year - 1.day
        end
      end
    end

    context 'not forced' do
      let!(:fulltime) { FactoryBot.create(:user, :fulltime, join_date: join_date) }
      let!(:parttime) { FactoryBot.create(:user, :intern, join_date: join_date) }
      let!(:contractor) { FactoryBot.create(:user, :contractor, join_date: join_date) }
      let!(:user) { FactoryBot.create(:user, join_date: join_date - 1.day) }
      let!(:datetime) { Time.zone.local(2017, 5, 4, 9, 30) }

      context 'end of working month' do
        let(:join_date) { Daikichi::Config::Biz.time(monthly_lead_days, :days).before(Daikichi::Config::Biz.periods.before(datetime.end_of_month).first.end_time) - 2.years + join_date_based_leed_days.days }
        before do
          Timecop.freeze(Daikichi::Config::Biz.time(monthly_lead_days, :days).before(Daikichi::Config::Biz.periods.before(datetime.end_of_month).first.end_time))
          described_class.new.automatically_import
        end
        after { Timecop.return }

        it 'should run join date based import only for users that join_date anniversary is comming and monthly import without prebuild option for all users' do
          leave_times = LeaveTime.where(user_id: [fulltime.id, parttime.id, user.id, contractor.id])
          expect(leave_times.reload.size).to eq(1 + weekly_leave_types.size * 3 + join_date_based_leave_types.size * 2 - seniority_based_leave_types.size)

          join_date_based_leave_time = leave_times.find { |x| x.leave_type == join_date_based_leave_types.first.first }
          join_anniversary = fulltime.next_join_anniversary
          expect(join_date_based_leave_time.effective_date).to  eq join_anniversary
          expect(join_date_based_leave_time.expiration_date).to eq join_anniversary + 1.year - 1.day
        end
      end

      context 'not end of working month' do
        let(:join_date) { Date.current.end_of_month + 3.days - 2.years + join_date_based_leed_days.days }
        before do
          if (Date.current.end_of_month + 3.days - 2.years).month <= 2 && (Date.current.end_of_month + 3.days - 2.years).leap?
            Timecop.freeze(Date.current.end_of_month + 2.days)
          else
            Timecop.freeze(Date.current.end_of_month + 3.days)
          end
          described_class.new.automatically_import
        end
        after { Timecop.return }

        it 'should run join date based import for users that join_date anniversary is comming only' do
          leave_times = LeaveTime.where(user_id: [fulltime.id, parttime.id, user.id, contractor.id])

          join_date_based_leave_time = leave_times.find { |x| x.leave_type == join_date_based_leave_types.first.first }
          join_anniversary = fulltime.next_join_anniversary
          expect(join_date_based_leave_time.effective_date).to  eq join_anniversary
          expect(join_date_based_leave_time.expiration_date).to eq join_anniversary + 1.year - 1.day
        end
      end
    end
  end
end

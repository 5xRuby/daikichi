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
    context 'fulltime employee' do
      let(:user) { FactoryGirl.create(:user, :fulltime) }

      it 'should run both monthly and join date based import without prebuild settings' do
        leave_times = user.leave_times.reload
        expect(leave_times.size).to eq monthly_leave_types.size + join_date_based_leave_types.size
        monthly_leave_time = leave_times.find { |x| x.leave_type == monthly_leave_types.first.first }
        expect(monthly_leave_time.effective_date).to  eq Time.zone.today
        expect(monthly_leave_time.expiration_date).to eq Time.zone.today.end_of_month
      end

      context 'with specific assign_date' do
        let(:user)      { User.new(FactoryGirl.attributes_for(:user, :fulltime)) }
        let(:join_date) { Time.zone.local(2014, 11, 5).to_date }
          
        before do
          Timecop.freeze current_date
          user.join_date = join_date
          user.assign_leave_time = 'true'
        end
        after { Timecop.return }

        shared_examples 'import LeaveTime from join date' do |args|  
          let(:before_date)        { Time.zone.local(2012, 11, 5).to_date }
          #let(:join_date)          { Time.zone.local(2014, 11, 5).to_date }
          let(:after_join_date)    { Time.zone.local(2015, 11, 5).to_date }
          let(:current_date)       { Time.zone.local(2016, 11, 5).to_date }

          let(:total_years)  { current_date.year - join_date.year + 1 }
          let(:total_months) { 12 * ( current_date.year - join_date.year) + (current_date.month - join_date.month) + 1 }

          it 'should import join date based LeaveTime from join date to current date without prebuild settings' do
            join_date_based_leave_types.map(&:first).each do |leave_type|
              expect(user.leave_times.where(leave_type: leave_type).size).to eq total_years 
              date = join_date
              user.leave_times.where(leave_type: leave_type).each do |leave_time|
                expect(leave_time.effective_date).to eq date
                expect(leave_time.expiration_date).to eq date.next_year - 1.day
                date = date.next_year
              end
            end
          end

          it 'should import monthly LeaveTime from join date to current date without prebuild settings' do
            monthly_leave_types.map(&:first).each do |leave_type|
              expect(user.leave_times.where(leave_type: leave_type).size).to eq total_months
              date = join_date
              user.leave_times.where(leave_type: leave_type).each do |leave_time|
                expect(leave_time.effective_date).to eq date
                expect(leave_time.expiration_date).to eq date.end_of_month
                date = date.next_month.beginning_of_month
              end
            end
          end
        end

        context 'assign date before join date' do
          before do
            user.assign_date = before_date
            user.save!
          end
          it_should_behave_like 'import LeaveTime from join date'
        end

        context 'assign date on join date' do
          before do
            user.assign_date = join_date
            user.save!
          end
          it_should_behave_like 'import LeaveTime from join date'
        end

        context 'assign date after join date' do
          let(:after_join_date)    { Time.zone.local(2015, 11, 5).to_date }
          let(:current_date)       { Time.zone.local(2016, 11, 5).to_date }
          let(:after_current_date) { Time.zone.local(2018, 11, 5).to_date }
          context 'assign date before current date' do
            let(:total_years)  { current_date.year - after_join_date.year + 1 }
            let(:total_months) { 12 * ( current_date.year - after_join_date.year) + (current_date.month - after_join_date.month) + 1 }
            before do
              user.assign_date = after_join_date
              user.save!
            end

            it 'should import join date based LeaveTime from assign date to current date without prebuild settings' do
              join_date_based_leave_types.map(&:first).each do |leave_type|
                expect(user.leave_times.where(leave_type: leave_type).count).to eq total_years
                date = after_join_date
                user.leave_times.where(leave_type: leave_type).each do |leave_time|
                  expect(leave_time.effective_date).to eq date
                  expect(leave_time.expiration_date).to eq date.next_year - 1.day
                  date = date.next_year
                end
              end
            end

            it 'should import monthly LeaveTime from assign date to current date without prebuild settings' do
              monthly_leave_types.map(&:first).each do |leave_type|
                expect(user.leave_times.where(leave_type: leave_type).size).to eq total_months
                date = after_join_date
                user.leave_times.where(leave_type: leave_type).each do |leave_time|
                  expect(leave_time.effective_date).to eq date
                  expect(leave_time.expiration_date).to eq date.end_of_month
                  date = date.next_month.beginning_of_month
                end
              end
            end
          end

          context 'assign date after current date' do
            before do
              user.assign_date = after_current_date
              user.save!
            end

            it 'should import each type of join date based LeaveTime according to assign date without prebuild settings' do
              join_date_based_leave_types.map(&:first).each do |leave_type|
                leave_times = user.leave_times.where(leave_type: leave_type)
                expect(leave_times.size).to eq 1
                expect(leave_times.first.effective_date).to eq after_current_date
                expect(leave_times.first.expiration_date).to eq after_current_date.next_year - 1.day
              end
            end

            it 'should import each type of monthly LeaveTime according to assign date without prebuild settings' do
              monthly_leave_types.map(&:first).each do |leave_type|
                leave_times = user.leave_times.where(leave_type: leave_type)
                expect(leave_times.size).to eq 1
                expect(leave_times.first.effective_date).to eq after_current_date
                expect(leave_times.first.expiration_date).to eq after_current_date.end_of_month
              end
            end
          end
        end
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

      context 'with specific assign date' do
        let(:user)      { User.new(FactoryGirl.attributes_for(:user, :parttime)) }
        let(:join_date) { Time.zone.local(2014, 11, 5).to_date }
          
        before do
          Timecop.freeze current_date
          user.join_date = join_date
          user.assign_leave_time = 'true'
        end
        after { Timecop.return }

        shared_examples 'import LeaveTime from join date' do |args|  
          let(:before_date)        { Time.zone.local(2012, 11, 5).to_date }
          # let(:join_date)          { Time.zone.local(2014, 11, 5).to_date }
          let(:after_join_date)    { Time.zone.local(2015, 11, 5).to_date }
          let(:current_date)       { Time.zone.local(2016, 11, 5).to_date }

          let(:total_years)  { current_date.year - join_date.year + 1 }
          let(:total_months) { 12 * ( current_date.year - join_date.year) + (current_date.month - join_date.month) + 1 }

          it 'should import join date based LeaveTime from join date to current date without prebuild settings' do
            join_date_based_leave_types.map(&:first).each do |leave_type|
              next if seniority_based_leave_types.map(&:first).include? leave_type
              expect(user.leave_times.where(leave_type: leave_type).size).to eq total_years 
              date = join_date
              user.leave_times.where(leave_type: leave_type).each do |leave_time|
                expect(leave_time.effective_date).to eq date
                expect(leave_time.expiration_date).to eq date.next_year - 1.day
                date = date.next_year
              end
            end
          end

          it 'should not import seniority based LeaveTime' do
            seniority_based_leave_types.map(&:first).each do |leave_type|
              expect(user.leave_times.where(leave_type: leave_type).any?).to be_falsey
            end
          end

          it 'should import monthly LeaveTime from join date to current date without prebuild settings' do
            monthly_leave_types.map(&:first).each do |leave_type|
              expect(user.leave_times.where(leave_type: leave_type).size).to eq total_months
              date = join_date
              user.leave_times.where(leave_type: leave_type).each do |leave_time|
                expect(leave_time.effective_date).to eq date
                expect(leave_time.expiration_date).to eq date.end_of_month
                date = date.next_month.beginning_of_month
              end
            end
          end
        end

        context 'assign date before join date' do
          before do
            user.assign_date = before_date
            user.save!
          end
          it_should_behave_like 'import LeaveTime from join date'
        end

        context 'assign date on join date' do
          before do
            user.assign_date = join_date
            user.save!
          end
          it_should_behave_like 'import LeaveTime from join date'
        end

        context 'assign date after join date' do
          let(:join_date)          { Time.zone.local(2014, 11, 5).to_date }
          let(:after_join_date)    { Time.zone.local(2015, 11, 5).to_date }
          let(:current_date)       { Time.zone.local(2016, 11, 5).to_date }
          let(:after_current_date) { Time.zone.local(2018, 11, 5).to_date }
          context 'assign date before current date' do
            let(:total_years)  { current_date.year - after_join_date.year + 1 }
            let(:total_months) { 12 * ( current_date.year - after_join_date.year) + (current_date.month - after_join_date.month) + 1 }
            before do
              user.assign_date = after_join_date
              user.save!
            end

            it 'should import join date based LeaveTime from assign date to current date without prebuild settings' do
              join_date_based_leave_types.map(&:first).each do |leave_type|
                next if seniority_based_leave_types.map(&:first).include? leave_type
                expect(user.leave_times.where(leave_type: leave_type).count).to eq total_years
                date = after_join_date
                user.leave_times.where(leave_type: leave_type).each do |leave_time|
                  expect(leave_time.effective_date).to eq date
                  expect(leave_time.expiration_date).to eq date.next_year - 1.day
                  date = date.next_year
                end
              end
            end

            it 'should not import seniority based LeaveTime' do
              seniority_based_leave_types.map(&:first).each do |leave_type|
                expect(user.leave_times.where(leave_type: leave_type).any?).to be_falsey
              end
            end

            it 'should import monthly LeaveTime from assign date to current date without prebuild settings' do
              monthly_leave_types.map(&:first).each do |leave_type|
                expect(user.leave_times.where(leave_type: leave_type).size).to eq total_months
                date = after_join_date
                user.leave_times.where(leave_type: leave_type).each do |leave_time|
                  expect(leave_time.effective_date).to eq date
                  expect(leave_time.expiration_date).to eq date.end_of_month
                  date = date.next_month.beginning_of_month
                end
              end
            end
          end

          context 'assign date after current date' do
            before do
              user.assign_date = after_current_date
              user.save!
            end

            it 'should import each type of join date based LeaveTime according to assign date without prebuild settings' do
              join_date_based_leave_types.map(&:first).each do |leave_type|
                next if seniority_based_leave_types.map(&:first).include? leave_type
                leave_times = user.leave_times.where(leave_type: leave_type)
                expect(leave_times.size).to eq 1
                expect(leave_times.first.effective_date).to eq after_current_date
                expect(leave_times.first.expiration_date).to eq after_current_date.next_year - 1.day
              end
            end

            it 'should not import seniority based LeaveTime' do
              seniority_based_leave_types.map(&:first).each do |leave_type|
                expect(user.leave_times.where(leave_type: leave_type).any?).to be_falsey
              end
            end

            it 'should import each type of monthly LeaveTime according to assign date without prebuild settings' do
              monthly_leave_types.map(&:first).each do |leave_type|
                leave_times = user.leave_times.where(leave_type: leave_type)
                expect(leave_times.size).to eq 1
                expect(leave_times.first.effective_date).to eq after_current_date
                expect(leave_times.first.expiration_date).to eq after_current_date.end_of_month
              end
            end
          end
        end
      end
    end
  end

  describe '.join_date_based_import' do
    before do
      User.skip_callback(:create, :after, :auto_assign_leave_time)
      LeaveTimeBuilder.new(user).join_date_based_import
    end

    after do
      User.set_callback(:create, :after, :auto_assign_leave_time)
    end

    context 'fulltime employee' do
      let!(:user) { FactoryGirl.create(:user, :fulltime) }

      it 'should get seniority_based leave_times' do
        leave_times = user.leave_times
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
        leave_times = user.leave_times
        expect(leave_times.size).to eq join_date_based_leave_types.size - seniority_based_leave_types.size
        leave_time = leave_times.first
        initial_quota = join_date_based_leave_types.select { |lt| lt.first == leave_time.leave_type }.first.second['quota'] * 8
        expect(leave_time.quota).to eq initial_quota
        expect(leave_time.usable_hours).to eq initial_quota
        expect(leave_time.used_hours).to eq 0
        expect(leave_time.effective_date).to  eq user.next_join_anniversary
        expect(leave_time.expiration_date).to eq user.next_join_anniversary + 1.year - 1.day
      end
    end
  end

  describe '.monthly_import' do
    before do
      User.skip_callback(:create, :after, :auto_assign_leave_time)
    end

    after do
      User.set_callback(:create, :after, :auto_assign_leave_time)
    end

    context 'prebuild' do
      before do
        LeaveTimeBuilder.new(user).monthly_import(prebuild: true)
      end

      it 'is build for the comming month' do
        leave_times = user.leave_times.reload
        expect(leave_times.size).to eq monthly_leave_types.size
        leave_time = leave_times.first
        initial_quota = monthly_leave_types.select { |lt| lt.first == leave_time.leave_type }.first.second['quota'] * 8
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
        initial_quota = monthly_leave_types.select { |lt| lt.first == leave_time.leave_type }.first.second['quota'] * 8
        expect(leave_time.quota).to eq initial_quota
        expect(leave_time.usable_hours).to eq initial_quota
        expect(leave_time.used_hours).to eq 0
        expect(leave_time.effective_date).to  eq Time.zone.today
        expect(leave_time.expiration_date).to eq Time.zone.today.end_of_month
      end
    end
  end
end

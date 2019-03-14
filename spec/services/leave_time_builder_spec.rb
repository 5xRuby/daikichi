# frozen_string_literal: true
require 'rails_helper'

describe LeaveTimeBuilder do
  let(:user) { FactoryGirl.create(:user, assign_date: Time.zone.today) }
  let(:monthly_leave_types) { Settings.leave_types.to_a.select { |lt| lt.second['creation'] == 'monthly' } }
  let(:weekly_leave_types) { Settings.leave_types.to_a.select { |lt| lt.second['creation'] == 'weekly' } }
  let(:join_date_based_leave_types) { Settings.leave_types.to_a.select { |lt| lt.second['creation'] == 'join_date_based' } }
  let(:seniority_based_leave_types) do
    join_date_based_leave_types.select do |lt|
      !(lt.second.dig('quota').is_a? Integer) && lt.second.dig('quota', 'type') == 'seniority_based'
    end
  end
  let(:join_date_based_leed_day) { Settings.leed_days.join_date_based.day }

  describe '.automatically_import' do
    context 'fulltime employee' do
      context 'import join date based LeaveTime with specific assign_date' do
        let(:user) { User.new(FactoryGirl.attributes_for(:user, :fulltime)) }
        let(:current_date) { Date.parse '2017/06/14' }

        before do
          Timecop.freeze current_date
          user.assign_leave_time = '1'
        end
        after { Timecop.return }

        def join_date_based_leave_times(user)
          join_date_based_leave_types.map(&:first).each do |leave_type|
            yield user.leave_times.where(leave_type: leave_type)
          end
        end

        context 'join date before current date a year' do
          let(:join_date) { current_date - 1.year - 1.month }
          let(:before_join_date) { join_date - 1.month }
          let(:after_join_date_before_current_date) { join_date + 1.month }
          let(:after_current_date) { current_date + 1.month }
          before { user.join_date = join_date }

          it 'should build LeaveTime based on join_date when assign_date is before join_date without prebuild settings' do
            user.assign_date = before_join_date.to_s
            user.save!
            join_date_based_leave_times(user) do |leave_times|
              expect(leave_times.count).to eq 2
              expect(leave_times.first.effective_date).to eq Date.parse '2016/05/14'
              expect(leave_times.first.expiration_date).to eq Date.parse '2017/05/13'
              expect(leave_times.second.effective_date).to eq Date.parse '2017/05/14'
              expect(leave_times.second.expiration_date).to eq Date.parse '2018/05/13'
            end
          end

          it 'should build LeaveTime based on join_date when assign_date is on join_date without prebuild settings' do
            user.assign_date = join_date.to_s
            user.save!
            join_date_based_leave_times(user) do |leave_times|
              expect(leave_times.count).to eq 2
              expect(leave_times.first.effective_date).to eq Date.parse '2016/05/14'
              expect(leave_times.first.expiration_date).to eq Date.parse '2017/05/13'
              expect(leave_times.second.effective_date).to eq Date.parse '2017/05/14'
              expect(leave_times.second.expiration_date).to eq Date.parse '2018/05/13'
            end
          end

          it 'should build LeaveTime based on assign_date when assign_date is after join_date and before current date without prebuild settings' do
            user.assign_date = after_join_date_before_current_date.to_s
            user.save!
            join_date_based_leave_times(user) do |leave_times|
              expect(leave_times.count).to eq 2
              expect(leave_times.first.effective_date).to eq Date.parse '2016/06/14'
              expect(leave_times.first.expiration_date).to eq Date.parse '2017/05/13'
              expect(leave_times.second.effective_date).to eq Date.parse '2017/05/14'
              expect(leave_times.second.expiration_date).to eq Date.parse '2018/05/13'
            end
          end

          it 'should build LeaveTime based on assign_date when assign_date is after current_date without prebuild settings' do
            user.assign_date = after_current_date.to_s
            user.save!
            join_date_based_leave_times(user) do |leave_times|
              expect(leave_times.count).to eq 1
              expect(leave_times.first.effective_date).to eq Date.parse '2017/07/14'
              expect(leave_times.first.expiration_date).to eq Date.parse '2018/05/13'
            end
          end

          it 'should build LeaveTime based on assign_date when assign_date is after current date and after this year leed day' do
            user.join_date = current_date + join_date_based_leed_day - 2.years
            user.assign_date = (current_date + join_date_based_leed_day).to_s
            user.save!
            join_date_based_leave_times(user) do |leave_times|
              expect(leave_times.count).to eq 1
              expect(leave_times.first.effective_date).to eq Date.parse '2017/08/13'
              expect(leave_times.first.expiration_date).to eq Date.parse '2018/08/12'
            end
          end

          it 'should build LeaveTime based on assign_date when assign_date is after current date and before this year leed day' do
            user.join_date = current_date + join_date_based_leed_day - 2.years + 1.day
            user.assign_date = (current_date + join_date_based_leed_day + 1.day).to_s
            user.save!
            join_date_based_leave_times(user) do |leave_times|
              expect(leave_times.any?).to be_falsey
            end
          end
        end

        context 'join date before current date within a year' do
          let(:join_date) { current_date - 1.month }
          let(:before_join_date) { join_date - 1.day }
          let(:after_join_date_before_current_date) { join_date + 1.day }
          before { user.join_date = join_date }

          it 'should build LeaveTime based on join_date when assign_date is before join_date without prebuild settings' do
            user.assign_date = before_join_date.to_s
            user.save!
            join_date_based_leave_times(user) do |leave_times|
              expect(leave_times.count).to eq 1
              expect(leave_times.first.effective_date).to eq Date.parse '2017/05/14'
              expect(leave_times.first.expiration_date).to eq Date.parse '2018/05/13'
            end
          end

          it 'should build LeaveTime based on join_date when assign_date is on join_date without prebuild settings' do
            user.assign_date = join_date.to_s
            user.save!
            join_date_based_leave_times(user) do |leave_times|
              expect(leave_times.count).to eq 1
              expect(leave_times.first.effective_date).to eq Date.parse '2017/05/14'
              expect(leave_times.first.expiration_date).to eq Date.parse '2018/05/13'
            end
          end

          it 'should build LeaveTime based on assign_date when assign_date is after join_date and before current date without prebuild settings' do
            user.assign_date = after_join_date_before_current_date.to_s
            user.save!
            join_date_based_leave_times(user) do |leave_times|
              expect(leave_times.count).to eq 1
              expect(leave_times.first.effective_date).to eq Date.parse '2017/05/15'
              expect(leave_times.first.expiration_date).to eq Date.parse '2018/05/13'
            end
          end
        end
      end

      context 'import monthly LeaveTime with specific assign_date' do
        let(:user) { User.new(FactoryGirl.attributes_for(:user, :fulltime)) }
        let(:current_date) { Date.parse '2017/06/14' }
        join_date = Date.parse('2017/06/14') - 1.year - 1.month
        before_join_date = join_date - 1.month
        after_join_date_before_current_date = join_date + 1.month
        let(:after_current_date) { current_date + 1.month }

        before do
          Timecop.freeze current_date
          user.assign_leave_time = '1'
          user.join_date = join_date
        end
        after { Timecop.return }

        def monthly_leave_times(user)
          monthly_leave_types.map(&:first).each do |leave_type|
            yield user.leave_times.where(leave_type: leave_type)
          end
        end

        shared_examples 'build monthly LeaveTime' do |params|
          it "should build LeaveTime based on #{params[:based_on]} when #{params[:when]} without prebuild settings" do
            user.assign_date = params[:assign_date].to_s
            user.save!
            monthly_total_count = if params[:based_on] == 'join_date'
                                    (current_date.year - user.join_date.year) * 12 + (current_date.month - user.join_date.month + 1)
                                  else
                                    (current_date.year - user.assign_date.year) * 12 + (current_date.month - user.assign_date.month + 1)
                                  end
            monthly_leave_times(user) do |leave_times|
              expect(leave_times.count).to eq monthly_total_count
              start_date = params[:based_on] == 'join_date' ? user.join_date : user.assign_date
              end_date = start_date.end_of_month
              leave_times.each do |leave_time|
                expect(leave_time.effective_date).to eq start_date
                expect(leave_time.expiration_date).to eq end_date
                start_date = end_date + 1.day
                end_date = start_date.end_of_month
              end
            end
          end
        end

        it_should_behave_like 'build monthly LeaveTime', based_on: 'join_date', when: 'assign_date is before join_date', assign_date: before_join_date
        it_should_behave_like 'build monthly LeaveTime', based_on: 'join_date', when: 'assign_date is on join_date', assign_date: join_date
        it_should_behave_like 'build monthly LeaveTime', based_on: 'assign_date', when: 'assign_date is after join_date and before current_date', assign_date: after_join_date_before_current_date
        it 'should build LeaveTime based on assign_date when assign_date is after current_date without prebuild settings' do
          user.assign_date = after_current_date.to_s
          user.save!
          monthly_leave_times(user) do |leave_times|
            expect(leave_times.any?).to be_falsey
          end
        end
      end
    end

    context 'partime employee' do
      context 'import join date based LeaveTime with specific assign_date' do
        let(:user) { User.new(FactoryGirl.attributes_for(:user, :intern)) }
        let(:current_date) { Date.parse '2017/06/14' }

        before do
          Timecop.freeze current_date
          user.assign_leave_time = '1'
        end
        after { Timecop.return }

        def join_date_based_leave_times(user)
          join_date_based_leave_types.map(&:first).each do |leave_type|
            yield user.leave_times.where(leave_type: leave_type), leave_type
          end
        end

        context 'join date before current date a year' do
          let(:join_date) { current_date - 1.year - 1.month }
          let(:before_join_date) { join_date - 1.month }
          let(:after_join_date_before_current_date) { join_date + 1.month }
          let(:after_current_date) { current_date + 1.month }
          before { user.join_date = join_date }

          it 'should build LeaveTime based on join_date when assign_date is before join_date without prebuild settings' do
            user.assign_date = before_join_date.to_s
            user.save!
            join_date_based_leave_times(user) do |leave_times, leave_type|
              if seniority_based_leave_types.map(&:first).include?(leave_type)
                expect(leave_times.any?).to be_falsey
                next
              end
              expect(leave_times.count).to eq 2
              expect(leave_times.first.effective_date).to eq Date.parse '2016/05/14'
              expect(leave_times.first.expiration_date).to eq Date.parse '2017/05/13'
              expect(leave_times.second.effective_date).to eq Date.parse '2017/05/14'
              expect(leave_times.second.expiration_date).to eq Date.parse '2018/05/13'
            end
          end

          it 'should build LeaveTime based on join_date when assign_date is on join_date without prebuild settings' do
            user.assign_date = join_date.to_s
            user.save!
            join_date_based_leave_times(user) do |leave_times, leave_type|
              if seniority_based_leave_types.map(&:first).include?(leave_type)
                expect(leave_times.any?).to be_falsey
                next
              end
              expect(leave_times.count).to eq 2
              expect(leave_times.first.effective_date).to eq Date.parse '2016/05/14'
              expect(leave_times.first.expiration_date).to eq Date.parse '2017/05/13'
              expect(leave_times.second.effective_date).to eq Date.parse '2017/05/14'
              expect(leave_times.second.expiration_date).to eq Date.parse '2018/05/13'
            end
          end

          it 'should build LeaveTime based on assign_date when assign_date is after join_date and before current date without prebuild settings' do
            user.assign_date = after_join_date_before_current_date.to_s
            user.save!
            join_date_based_leave_times(user) do |leave_times, leave_type|
              if seniority_based_leave_types.map(&:first).include?(leave_type)
                expect(leave_times.any?).to be_falsey
                next
              end
              expect(leave_times.count).to eq 2
              expect(leave_times.first.effective_date).to eq Date.parse '2016/06/14'
              expect(leave_times.first.expiration_date).to eq Date.parse '2017/05/13'
              expect(leave_times.second.effective_date).to eq Date.parse '2017/05/14'
              expect(leave_times.second.expiration_date).to eq Date.parse '2018/05/13'
            end
          end

          it 'should build LeaveTime based on assign_date when assign_date is after current_date without prebuild settings' do
            user.assign_date = after_current_date.to_s
            user.save!
            join_date_based_leave_times(user) do |leave_times, leave_type|
              if seniority_based_leave_types.map(&:first).include?(leave_type)
                expect(leave_times.any?).to be_falsey
                next
              end
              expect(leave_times.count).to eq 1
              expect(leave_times.first.effective_date).to eq Date.parse '2017/07/14'
              expect(leave_times.first.expiration_date).to eq Date.parse '2018/05/13'
            end
          end

          it 'should build LeaveTime based on assign_date when assign_date is after current date and after this year leed day' do
            user.join_date = current_date + join_date_based_leed_day - 2.years
            user.assign_date = (current_date + join_date_based_leed_day).to_s
            user.save!
            join_date_based_leave_times(user) do |leave_times, leave_type|
              if seniority_based_leave_types.map(&:first).include?(leave_type)
                expect(leave_times.any?).to be_falsey
                next
              end
              expect(leave_times.count).to eq 1
              expect(leave_times.first.effective_date).to eq Date.parse '2017/08/13'
              expect(leave_times.first.expiration_date).to eq Date.parse '2018/08/12'
            end
          end

          it 'should build LeaveTime based on assign_date when assign_date is after current date and before this year leed day' do
            user.join_date = current_date + join_date_based_leed_day - 2.years + 1.day
            user.assign_date = (current_date + join_date_based_leed_day + 1.day).to_s
            user.save!
            join_date_based_leave_times(user) do |leave_times, leave_type|
              if seniority_based_leave_types.map(&:first).include?(leave_type)
                expect(leave_times.any?).to be_falsey
                next
              end
              expect(leave_times.any?).to be_falsey
            end
          end
        end

        context 'join date before current date within a year' do
          let(:join_date) { current_date - 1.month }
          let(:before_join_date) { join_date - 1.day }
          let(:after_join_date_before_current_date) { join_date + 1.day }
          before { user.join_date = join_date }

          it 'should build LeaveTime based on join_date when assign_date is before join_date without prebuild settings' do
            user.assign_date = before_join_date.to_s
            user.save!
            join_date_based_leave_times(user) do |leave_times, leave_type|
              if seniority_based_leave_types.map(&:first).include?(leave_type)
                expect(leave_times.any?).to be_falsey
                next
              end
              expect(leave_times.count).to eq 1
              expect(leave_times.first.effective_date).to eq Date.parse '2017/05/14'
              expect(leave_times.first.expiration_date).to eq Date.parse '2018/05/13'
            end
          end

          it 'should build LeaveTime based on join_date when assign_date is on join_date without prebuild settings' do
            user.assign_date = join_date.to_s
            user.save!
            join_date_based_leave_times(user) do |leave_times, leave_type|
              if seniority_based_leave_types.map(&:first).include?(leave_type)
                expect(leave_times.any?).to be_falsey
                next
              end
              expect(leave_times.count).to eq 1
              expect(leave_times.first.effective_date).to eq Date.parse '2017/05/14'
              expect(leave_times.first.expiration_date).to eq Date.parse '2018/05/13'
            end
          end

          it 'should build LeaveTime based on assign_date when assign_date is after join_date and before current date without prebuild settings' do
            user.assign_date = after_join_date_before_current_date.to_s
            user.save!
            join_date_based_leave_times(user) do |leave_times, leave_type|
              if seniority_based_leave_types.map(&:first).include?(leave_type)
                expect(leave_times.any?).to be_falsey
                next
              end
              expect(leave_times.count).to eq 1
              expect(leave_times.first.effective_date).to eq Date.parse '2017/05/15'
              expect(leave_times.first.expiration_date).to eq Date.parse '2018/05/13'
            end
          end
        end
      end

      context 'import monthly LeaveTime with specific assign_date' do
        let(:user) { User.new(FactoryGirl.attributes_for(:user, :fulltime)) }
        let(:current_date) { Date.parse '2017/06/14' }
        join_date = Date.parse('2017/06/14') - 1.year - 1.month
        before_join_date = join_date - 1.month
        after_join_date_before_current_date = join_date + 1.month
        let(:after_current_date) { current_date + 1.month }

        before do
          Timecop.freeze current_date
          user.assign_leave_time = '1'
          user.join_date = join_date
        end
        after { Timecop.return }

        def monthly_leave_times(user)
          monthly_leave_types.map(&:first).each do |leave_type|
            yield user.leave_times.where(leave_type: leave_type)
          end
        end

        shared_examples 'build monthly LeaveTime' do |params|
          it "should build LeaveTime based on #{params[:based_on]} when #{params[:when]} without prebuild settings" do
            user.assign_date = params[:assign_date].to_s
            user.save!
            monthly_total_count = if params[:based_on] == 'join_date'
                                    (current_date.year - user.join_date.year) * 12 + (current_date.month - user.join_date.month + 1)
                                  else
                                    (current_date.year - user.assign_date.year) * 12 + (current_date.month - user.assign_date.month + 1)
                                  end
            monthly_leave_times(user) do |leave_times|
              expect(leave_times.count).to eq monthly_total_count
              start_date = params[:based_on] == 'join_date' ? user.join_date : user.assign_date
              end_date = start_date.end_of_month
              leave_times.each do |leave_time|
                expect(leave_time.effective_date).to eq start_date
                expect(leave_time.expiration_date).to eq end_date
                start_date = end_date + 1.day
                end_date = start_date.end_of_month
              end
            end
          end
        end

        it_should_behave_like 'build monthly LeaveTime', based_on: 'join_date', when: 'assign_date is before join_date', assign_date: before_join_date
        it_should_behave_like 'build monthly LeaveTime', based_on: 'join_date', when: 'assign_date is on join_date', assign_date: join_date
        it_should_behave_like 'build monthly LeaveTime', based_on: 'assign_date', when: 'assign_date is after join_date and before current_date', assign_date: after_join_date_before_current_date
        it 'should build LeaveTime based on assign_date when assign_date is after current_date without prebuild settings' do
          user.assign_date = after_current_date.to_s
          user.save!
          monthly_leave_times(user) do |leave_times|
            expect(leave_times.any?).to be_falsey
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
      let(:user) { FactoryGirl.create(:user, :intern) }

      it 'should not get seniority_based leave_times' do
        leave_times = user.leave_times
        expect(leave_times.size).to eq join_date_based_leave_types.size - seniority_based_leave_types.size
        leave_time = leave_times.first
        initial_quota = join_date_based_leave_types.find { |lt| lt.first == leave_time.leave_type }.second['quota'] * 8
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
        unless monthly_leave_types.blank?
          leave_times = user.leave_times.reload
          expect(leave_times.size).to eq monthly_leave_types.size
          leave_time = leave_times.first
          initial_quota = monthly_leave_types.find { |lt| lt.first == leave_time.leave_type }.second['quota'] * 8
          expect(leave_time.quota).to eq initial_quota
          expect(leave_time.usable_hours).to eq initial_quota
          expect(leave_time.used_hours).to eq 0
          expect(leave_time.effective_date).to  eq Time.zone.today.next_month.beginning_of_month
          expect(leave_time.expiration_date).to eq Time.zone.today.next_month.end_of_month
        end
      end
    end

    context 'not prebuild' do
      before do
        LeaveTimeBuilder.new(user).monthly_import
      end

      it 'is build for current month' do
        unless monthly_leave_types.blank?
          leave_times = user.leave_times.reload
          expect(leave_times.size).to eq monthly_leave_types.size
          leave_time = leave_times.first
          initial_quota = monthly_leave_types.find { |lt| lt.first == leave_time.leave_type }.second['quota'] * 8
          expect(leave_time.quota).to eq initial_quota
          expect(leave_time.usable_hours).to eq initial_quota
          expect(leave_time.used_hours).to eq 0
          expect(leave_time.effective_date).to  eq Time.zone.today
          expect(leave_time.expiration_date).to eq Time.zone.today.end_of_month
        end
      end
    end
  end

  describe '.weekly_import' do
    before do
      User.skip_callback(:create, :after, :auto_assign_leave_time)
    end

    after do
      User.set_callback(:create, :after, :auto_assign_leave_time)
    end

    it 'create new user' do
      LeaveTimeBuilder.new(user).weekly_import(by_assign_date: true)
      leave_times = user.leave_times.reload
      expect(leave_times.size).to eq weekly_leave_types.size * 4
      date = Time.zone.today
      leave_time = leave_times.first
      initial_quota = weekly_leave_types.find { |lt| lt.first == leave_time.leave_type }.second['quota'] * 8
      expect(leave_time.quota).to eq initial_quota
      expect(leave_time.usable_hours).to eq initial_quota
      expect(leave_time.used_hours).to eq 0
      expect(leave_time.effective_date).to  eq user.assign_date
      expect(leave_time.expiration_date).to eq user.assign_date.end_of_week
    end

    it 'build leave time for after four weeks if today is Monday' do
      if Time.zone.today.monday?
        LeaveTimeBuilder.new(user).weekly_import
        leave_times = user.leave_times.reload
        expect(leave_times.size).to eq weekly_leave_types.size
        date = Time.zone.today
        leave_time = leave_times.first
        initial_quota = weekly_leave_types.find { |lt| lt.first == leave_time.leave_type }.second['quota'] * 8
        expect(leave_time.quota).to eq initial_quota
        expect(leave_time.usable_hours).to eq initial_quota
        expect(leave_time.used_hours).to eq 0
        expect(leave_time.effective_date).to  eq (date + 4.week).beginning_of_week
        expect(leave_time.expiration_date).to eq (date + 4.week).end_of_week
      end
    end

    it 'will not build leave time for after four weeks because today is not Monday' do
      unless Time.zone.today.monday?
        LeaveTimeBuilder.new(user).weekly_import
        leave_times = user.leave_times.reload
        expect(leave_times.size).to eq 0
        leave_time = leave_times.first
        expect(leave_time).to eq nil
      end
    end
  end
end

require 'rails_helper'

feature 'special type leave application' do
  context 'created' do
    let!(:user) { FactoryBot.create(:user, :fulltime, join_date: Date.current - 1.year - 1.day) }

    before :each do
      visit '/users/sign_in'
      login user.login_name, user.password
    end

    scenario 'menstrual' do
      visit '/leave_applications/new'
      within('form#new_leave_application') do
        select('生理假', from: 'leave_application_leave_type')
        find('[id^="leave_application_start_time"]').set('2018/02/12 09:30')
        find('[id^="leave_application_start_time"]').set('2018/02/12 18:30')
        fill_in('事由', with: 'menstrual')
      end
      click_button '送出'
      expect(page).to have_content '生理假'
    end

    scenario 'occpational_sick' do
      visit '/leave_applications/new'
      within('form#new_leave_application') do
        select('公傷病假', from: 'leave_application_leave_type')
        find('[id^="leave_application_start_time"]').set('2018/02/12 09:30')
        find('[id^="leave_application_start_time"]').set('2018/02/12 18:30')
        fill_in('事由', with: 'occpational_sick')
      end
      click_button '送出'
      expect(page).to have_content '公傷病假'
    end

    scenario 'official' do
      visit '/leave_applications/new'
      within('form#new_leave_application') do
        select('公假', from: 'leave_application_leave_type')
        find('[id^="leave_application_start_time"]').set('2018/02/12 09:30')
        find('[id^="leave_application_start_time"]').set('2018/02/12 18:30')
        fill_in('事由', with: 'official')
      end
      click_button '送出'
      expect(page).to have_content '公假'
    end

    scenario 'compassionate' do
      visit '/leave_applications/new'
      within('form#new_leave_application') do
        select('喪假', from: 'leave_application_leave_type')
        find('[id^="leave_application_start_time"]').set('2018/02/12 09:30')
        find('[id^="leave_application_start_time"]').set('2018/02/12 18:30')
        fill_in('事由', with: 'compassionate')
      end
      click_button '送出'
      expect(page).to have_content '喪假'
    end

    scenario 'marriage' do
      visit '/leave_applications/new'
      within('form#new_leave_application') do
        select('婚假', from: 'leave_application_leave_type')
        find('[id^="leave_application_start_time"]').set('2018/02/12 09:30')
        find('[id^="leave_application_start_time"]').set('2018/02/12 18:30')
        fill_in('事由', with: 'marriage')
      end
      click_button '送出'
      expect(page).to have_content '婚假'
    end

    scenario 'maternity' do
      visit '/leave_applications/new'
      within('form#new_leave_application') do
        select('產假', from: 'leave_application_leave_type')
        find('[id^="leave_application_start_time"]').set('2018/02/12 09:30')
        find('[id^="leave_application_start_time"]').set('2018/02/12 18:30')
        fill_in('事由', with: 'maternity')
      end
      click_button '送出'
      expect(page).to have_content '產假'
    end

    scenario 'paid_vacation' do
      visit '/leave_applications/new'
      within('form#new_leave_application') do
        select('旅遊假', from: 'leave_application_leave_type')
        find('[id^="leave_application_start_time"]').set('2018/02/12 09:30')
        find('[id^="leave_application_start_time"]').set('2018/02/12 18:30')
        fill_in('事由', with: 'paid_vacation')
      end
      click_button '送出'
      expect(page).to have_content '旅遊假'
    end
  end

  context "verified" do
    let!(:user) { FactoryBot.create(:user, :manager, join_date: Date.current - 1.year - 1.day) }
    let!(:leave_application) { LeaveApplication.create(user_id: user.id, leave_type: 'maternity', start_time: Time.zone.local(Time.current.year, 8, 15, 9, 30, 0), end_time: Time.zone.local(Time.current.year, 8, 15, 18, 30, 0), description: 'test') }
    let!(:leave_application_paid_vaca) { LeaveApplication.create(user_id: user.id, leave_type: 'paid_vacation', start_time: Time.zone.local(Time.current.year, 8, 15, 9, 30, 0), end_time: Time.zone.local(Time.current.year, 8, 15, 18, 30, 0), description: 'test') }

    before :each do
      visit '/users/sign_in'
      login user.login_name, user.password
    end

    scenario 'menstrual' do
      visit "/backend/leave_applications/#{leave_application.id}/verify"

      expect(page).to have_content '新增額度'
    end

    scenario 'paid_vacation' do
      visit "/backend/leave_applications/#{leave_application_vaca.id}/verify"

      expect(page).to have_content '新增額度'
    end
  end

  private

  def login(email, password)
    fill_in "員工帳號", with: email
    fill_in "密碼", with: password
    click_button "送出"
  end
end

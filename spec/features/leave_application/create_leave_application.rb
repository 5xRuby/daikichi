require 'rails_helper'

feature "create a special type leave application" do
  let!(:user) { FactoryGirl.create(:user, :fulltime, join_date: Date.current - 1.year - 1.day) }

  before :each do
    visit '/users/sign_in'
    login user.login_name, user.password
  end

  scenario "menstrual" do
    visit '/leave_applications/new'
    within("form#new_leave_application") do
      select('生理假', from: 'leave_application_leave_type')
      find('[id^="leave_application_start_time"]').set("2018/02/12 09:30")
      find('[id^="leave_application_start_time"]').set("2018/02/12 18:30")
      fill_in('事由', with: 'menstrual')
    end
    click_button '送出'
    expect(page).to have_content '生理假'
  end

  scenario "occpational_sick" do
    visit '/leave_applications/new'
    within("form#new_leave_application") do
      select('公傷病假', from: 'leave_application_leave_type')
      find('[id^="leave_application_start_time"]').set("2018/02/12 09:30")
      find('[id^="leave_application_start_time"]').set("2018/02/12 18:30")
      fill_in('事由', with: 'occpational_sick')
    end
    click_button '送出'
    expect(page).to have_content '公傷病假'
  end

  scenario "official" do
    visit '/leave_applications/new'
    within("form#new_leave_application") do
      select('公假', from: 'leave_application_leave_type')
      find('[id^="leave_application_start_time"]').set("2018/02/12 09:30")
      find('[id^="leave_application_start_time"]').set("2018/02/12 18:30")
      fill_in('事由', with: 'official')
    end
    click_button '送出'
    expect(page).to have_content '公假'
  end

  scenario "compassionate" do
    visit '/leave_applications/new'
    within("form#new_leave_application") do
      select('喪假', from: 'leave_application_leave_type')
      find('[id^="leave_application_start_time"]').set("2018/02/12 09:30")
      find('[id^="leave_application_start_time"]').set("2018/02/12 18:30")
      fill_in('事由', with: 'compassionate')
    end
    click_button '送出'
    expect(page).to have_content '喪假'
  end

  scenario "marriage" do
    visit '/leave_applications/new'
    within("form#new_leave_application") do
      select('婚假', from: 'leave_application_leave_type')
      find('[id^="leave_application_start_time"]').set("2018/02/12 09:30")
      find('[id^="leave_application_start_time"]').set("2018/02/12 18:30")
      fill_in('事由', with: 'marriage')
    end
    click_button '送出'
    expect(page).to have_content '婚假'
  end

  scenario "marriage" do
    visit '/leave_applications/new'
    within("form#new_leave_application") do
      select('婚假', from: 'leave_application_leave_type')
      find('[id^="leave_application_start_time"]').set("2018/02/12 09:30")
      find('[id^="leave_application_start_time"]').set("2018/02/12 18:30")
      fill_in('事由', with: 'marriage')
    end
    click_button '送出'
    expect(page).to have_content '婚假'
  end

  private

  def login(email, password)
    fill_in "員工帳號", with: email
    fill_in "密碼", with: password
    click_button "送出"
  end
end

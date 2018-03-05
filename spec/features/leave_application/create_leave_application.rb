require 'rails_helper'

feature "create a leave application" do
  let!(:fulltime) { FactoryGirl.create(:user, :fulltime, join_date: Date.current - 1.year - 1.day) }

  before :each do
    visit '/users/sign_in'
    login fulltime.login_name, fulltime.password
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

  private
  def login(email, password)
    fill_in "員工帳號", with: email
    fill_in "密碼", with: password
    click_button "送出"
  end
end

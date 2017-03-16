# frozen_string_literal: true
module ControllerMacros
  def login_user(user = FactoryGirl.create(:user))
    before(:each) do
      @request.env['devise.mapping'] = Devise.mappings[:user]
      sign_in user
    end
  end

  def login_employee
    login_user FactoryGirl.create(:user, :employee)
  end

  def login_manager
    login_user FactoryGirl.create(:user, :manager)
  end

  def login_hr
    login_user FactoryGirl.create(:user, :hr)
  end
end

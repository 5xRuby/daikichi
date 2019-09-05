# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)
    case user.role
    when 'manager', 'hr'
      can :manage, :all
    when 'employee', 'parttime', 'intern'
      can :read, LeaveTime, user_id: user.id
      can :manage, LeaveApplication, user_id: user.id
    when 'contractor'
      can :manage, LeaveApplication, user_id: user.id
    end
  end
end

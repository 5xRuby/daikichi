# frozen_string_literal: true
class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)
    case user.role
    when "manager", "admin"
      can :manage, :all
    when "employee"
      can :read, LeaveTime, user_id: user.id
      can :manage, LeaveApplication, user_id: user.id
    end
  end
end

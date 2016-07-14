# Ability
class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)
    case user.role
    when 'manager', 'admin'
      can :manage, :all
    when 'employee', 'probation'
      can :view, LeaveTime
    end
  end
end

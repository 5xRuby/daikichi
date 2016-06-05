# Ability
class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)
    case user.role
    when 'manager'
      can :manage, :all
    when 'employee', 'probation'
    end
  end
end

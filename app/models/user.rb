# User
class User < ApplicationRecord
  acts_as_paranoid
  has_many :leave_times

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  ROLES = %i(
    manager employee probation contractor
    vendor intern resigned pending
  ).freeze

  scope :employees, lambda {
    where('role in (?)', ROLES[0..2].map(&:to_s))
      .where('join_date < now()')
      .order(id: :desc)
  }

  def seniority(year = Date.today.year)
    if join_date.year == year
      1
    elsif join_date.year > year
      0
    else
      year - join_date.year + 1
    end
  end
end

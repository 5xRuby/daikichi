# frozen_string_literal: true
class User < ApplicationRecord
  acts_as_paranoid
  has_many :leave_times, -> { order("id DESC") }
  has_many :leave_applications, -> { order("id DESC") }
  has_many :bonus_leave_time_logs, -> { order("id DESC") }

  validates :login_name, uniqueness: { case_sensitive: false, scope: :deleted_at }
  validates :email, uniqueness: { case_sensitive: false, scope: :deleted_at }

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  ROLES = %i(manager hr employee contractor intern resigned pending).freeze

  scope :fulltime, -> {
    where("role in (?)", %w(manager employee hr))
      .where("join_date < now()")
      .order(id: :desc)
  }

  scope :parttime, -> {
    where("role in (?)", %w(contractor intern))
      .where("join_date < now()")
      .order(id: :desc)
  }

  def seniority(year = Time.now.year)
    if join_date.nil? or join_date.year > year
      0
    elsif employed_for_the_first_year? || employed_within_a_year?
      1
    else
      year - join_date.year + 1
    end
  end

  def fulltime?
    case role
    when "manager", "hr", "employee"
      true
    else
      false
    end
  end

  # 未滿第一年的年度
  def employed_for_the_first_year?(time = Time.now)
    join_date.year == time.year
  end

  def employed_within_a_year?(time = Time.now)
    time < (join_date + 1.year)
  end

  def get_refilled_annual
    leave_times.find_by(leave_type: "annual").refill
  end
end

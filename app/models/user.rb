# frozen_string_literal: true
class User < ApplicationRecord
  acts_as_paranoid
  has_many :leave_times, ->{ order("id DESC") }
  has_many :leave_applications, ->{ order("id DESC") }

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  ROLES = %i(
    manager employee contractor intern resigned pending admin
  ).freeze

  scope :fulltime, -> {
    where("role in (?)", %w(manager employee))
      .where("join_date < now()")
      .order(id: :desc)
  }

  scope :parttime, -> {
    where("role in (?)", %w(contractor intern))
      .where("join_date < now()")
      .order(id: :desc)
  }

  def seniority(year = Time.zone.today.year)
    if join_date.nil? or join_date.year > year
      0
    elsif join_date.year == year
      1
    else
      year - join_date.year + 1
    end
  end

  def fulltime?
    case role
    when "manager", "employee"
      true
    else
      false
    end
  end
end

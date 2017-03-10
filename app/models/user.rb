# frozen_string_literal: true
class User < ApplicationRecord
  acts_as_paranoid
  has_many :leave_times, -> { order("id DESC") }
  has_many :leave_applications, -> { order("id DESC") }
  has_many :bonus_leave_time_logs, -> { order("id DESC") }

  validates :name,       presence: true
  validates :login_name, presence: true,
                         uniqueness: { case_sensitive: false, scope: :deleted_at }
  validates :email,      presence: true,
                         uniqueness: { case_sensitive: false, scope: :deleted_at }
  validates :join_date,  presence: true

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  ROLES = %i(manager hr employee contractor intern resigned pending).freeze

  scope :filter_by_join_date, ->(month, date) {
    where(
      '(EXTRACT(MONTH FROM join_date), EXTRACT(DAY FROM join_date)) = (:month, :date)',
      month: month, date: date
    )
  }
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

  scope :with_leave_application_statistics, ->(year, month) {
    joins(:leave_applications, :leave_times)
    .includes(:leave_applications, :leave_times)
    .merge(LeaveApplication.leave_within_range(
      WorkingHours.advance_to_working_time(Time.new(year, month, 1)),
      WorkingHours.return_to_working_time(Time.new(year, month, 1).end_of_month))
      .approved
    )
  }

  ROLES.each do |role|
    define_method "is_#{role}?" do
      self.role.to_sym == role
    end
  end

  def seniority(time = Date.current)
    return 0 if !fulltime? || join_date >= Date.current
    @seniority ||= (join_date.nil? ? 0 : (time - join_date).to_i / 365)
  end

  def fulltime?
    %w(manager hr employee).include?(role)
  end

  def this_year_join_anniversary
    @this_year_join_anniversary ||= Time.zone.local(Date.current.year, join_date.month, join_date.day).to_date
  end

  def next_join_anniversary
    @next_join_anniversary ||= if this_year_join_anniversary < Time.current.to_date
                                 this_year_join_anniversary + 1.year
                               else
                                 this_year_join_anniversary
                               end
  end

  # TODO: change to pre-gen prev_not_effective
  def get_refilled_annual
    leave_times.find_by(leave_type: "annual").refill
  end
end

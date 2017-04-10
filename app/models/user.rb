# frozen_string_literal: true
class User < ApplicationRecord
  acts_as_paranoid
  has_many :leave_times, -> { order(id: :desc) }
  has_many :leave_applications, -> { order(id: :desc) }
  has_many :bonus_leave_time_logs, -> { order(id: :desc) }

  after_create :auto_assign_leave_time

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

  enum role: Settings.roles
  # %i(manager hr employee contractor intern resigned pending)

  scope :filter_by_join_date, ->(month, date) {
    where(
      '(EXTRACT(MONTH FROM join_date), EXTRACT(DAY FROM join_date)) = (:month, :date)',
      month: month, date: date
    )
  }

  scope :valid, -> {
    where('join_date <= :now', now: Date.current)
      .where.not(role: %w(pending resigned))
  }

  scope :fulltime, -> {
    where('role in (?)', %w(manager employee hr))
      .valid
      .order(id: :desc)
  }

  scope :parttime, -> {
    where('role in (?)', %w(contractor intern))
      .valid
      .order(id: :desc)
  }

  scope :with_leave_application_statistics, ->(year, month) {
    joins(:leave_applications, :leave_times)
      .includes(:leave_applications, :leave_times)
      .merge(LeaveApplication.leave_within_range(
        WorkingHours.advance_to_working_time(Time.zone.local(year, month, 1)),
        WorkingHours.return_to_working_time(Time.zone.local(year, month, 1).end_of_month)
      )
      .approved)
  }

  Settings.roles.each do |key, role|
    define_method "is_#{role}?" do
      self.role.to_s == role
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
    leave_times.find_by(leave_type: 'annual').refill
  end

  # Class method - Only used in Rspec Testing
  # def self.skip_assign_leave_time
  #   self.skip_callback :create, :after, :auto_assign_leave_time
  #   yield if block_given?
  #   self.set_callback :create, :after, :auto_assign_leave_time
  # end

  private

  def auto_assign_leave_time
    leave_time_builder = LeaveTimeBuilder.new self
    leave_time_builder.automatically_import
  end
  
end

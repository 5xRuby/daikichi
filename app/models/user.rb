# frozen_string_literal: true
class User < ApplicationRecord
  acts_as_paranoid
  has_many :leave_times
  has_many :leave_applications, -> { order(id: :desc) }
  has_many :bonus_leave_time_logs, -> { order(id: :desc) }
  attr_accessor :assign_leave_time, :assign_date

  after_create :auto_assign_leave_time

  validates :name,       presence: true
  validates :login_name, presence: true,
                         uniqueness: { case_sensitive: false, scope: :deleted_at }
  validates :email,      presence: true,
                         uniqueness: { case_sensitive: false, scope: :deleted_at }
  validates :join_date,  presence: true
  validate  :assign_leave_time_fields

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
      .where.not(role: %w[pending resigned])
  }

  scope :fulltime, -> {
    where('role in (?)', %w[manager employee hr])
      .valid
      .order(id: :desc)
  }

  scope :parttime, -> {
    where('role in (?)', %w[contractor intern])
      .valid
      .order(id: :desc)
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
    %w[manager hr employee].include?(role)
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

  private

  def valid_role?
    self.role != 'pending' and self.role != 'resigned'
  end

  def assign_leave_time_fields
    return if assign_leave_time == '0'
    errors.add(:assign_date, :blank) if assign_date.empty?
  end

  def auto_assign_leave_time
    return unless valid_role?
    if assign_leave_time == '1'
      leave_time_builder = LeaveTimeBuilder.new self
      leave_time_builder.automatically_import
    end
  end
end

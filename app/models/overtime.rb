class Overtime < ApplicationRecord
  belongs_to :user
  validates :description, :start_time, :end_time, presence: true
  validate :hours_should_be_positive_integer
  before_validation :assign_hours

  private

  def auto_calculated_minutes
    return @minutes = 0 unless start_time && end_time
    @minutes = Daikichi::Config::Biz.within(start_time, end_time).in_minutes
  end

  def assign_hours
    self.hours = self.send(:auto_calculated_minutes) / 60
  end

  def hours_should_be_positive_integer
    return if self.errors[:start_time].any? or self.errors[:end_time].any?
    errors.add(:end_time, :not_integer) if (@minutes % 60).nonzero? || !self.hours.positive?
    errors.add(:start_time, :should_be_earlier) unless self.end_time > self.start_time
  end
end

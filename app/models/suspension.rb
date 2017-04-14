class Suspension < ApplicationRecord
  belongs_to :user

  validates :start_date, :end_date, presence: true
  validate  :positive_range

  def days
    (self.end_date - self.start_date).to_i
  end

  private

  def positive_range
    unless end_date && start_date && end_date >= start_date
      errors.add(:start_date, :range_should_be_positive)
    end
  end
end

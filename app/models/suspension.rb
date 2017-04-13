class Suspension < ApplicationRecord
  belongs_to :user

  validates :start_date, :end_date, presence: true

  def days
    (self.end_date - self.start_date).to_i
  end
end

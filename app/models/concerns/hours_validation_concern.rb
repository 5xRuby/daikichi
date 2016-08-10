# frozen_string_literal: true
module HoursValidationConcern
  extend ActiveSupport::Concern

  included do
    private
    def validate_hours
      self.errors.add(:end_time, :not_integer) unless is_integer(self.start_time, self.end_time)
    end

    def is_integer(start_time, end_time)
      ((end_time - start_time) / 3600.0) % 1 == 0
    end
  end
end

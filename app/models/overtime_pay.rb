# frozen_string_literal: true

class OvertimePay < ApplicationRecord
  belongs_to :overtime
  belongs_to :user
end

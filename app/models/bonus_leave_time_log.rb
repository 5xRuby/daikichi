# frozen_string_literal: true

class BonusLeaveTimeLog < ApplicationRecord
  belongs_to :user
  belongs_to :manager, class_name: 'User', foreign_key: 'manager_id', inverse_of: :bonus_leave_time_log
end

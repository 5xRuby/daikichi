class OvertimePay < ApplicationRecord
  belongs_to :user
  belongs_to :overtime
end

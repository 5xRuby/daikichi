class OvertimePay < ApplicationRecord
  belongs_to :overtime
  belongs_to :user
end

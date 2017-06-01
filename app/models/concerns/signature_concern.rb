# frozen_string_literal: true
module SignatureConcern
  extend ActiveSupport::Concern

  included do
    def sign(manager)
      self.attributes = {
        manager_id: manager.id,
        sign_date: Time.current
      }
    end
  end

  # ClassMethods
  module ClassMethods
  end
end

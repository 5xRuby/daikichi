# frozen_string_literal: true
module Backend
  module OvertimesHelper
    def render_append_hours_options
      if current_object.may_approve? and current_object.leave?
        link_to t("title.backend/overtimes.append_quota"), add_leave_time_backend_overtime_path, class: 'btn btn-warning'
      elsif current_object.may_approve? and current_object.pay? && current_object.overtime_pay.nil?
        link_to t("title.backend/overtimes.append_overtime_pay"), add_compensatory_pay_backend_overtime_path, class: 'btn btn-warning'
      end
    end

    def render_download_button
      if params["q"].present?
        link_to t('.download_csv'), 
                statistics_backend_overtimes_path(format: 'csv', "q[year_eq]" => params["q"]["year_eq"], "q[month_eq]" => params["q"]["month_eq"] ),
                class: 'btn btn-success'
      else
        link_to t('.download_csv'), 
                statistics_backend_overtimes_path(format: 'csv'),
                class: 'btn btn-success'
      end
    end
  end
end
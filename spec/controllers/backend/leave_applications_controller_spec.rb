# frozen_string_literal: true
require "rails_helper"
RSpec.describe Backend::LeaveApplicationsController, type: :controller do
  render_views

  describe "statistics" do
    let(:params) { { year: Time.current.year, month: Time.current.month } }
    subject { get :statistics, params: params }

    context "not logged in" do
      include_examples "authorization failed"
    end

    context "logged in" do
      context "as employee" do
        login_employee
        include_examples "authorization failed"
      end

      context "as manager" do
        login_manager

        context "with records" do
          let(:year)  { Time.current.year }
          let(:month) { Time.current.month }
          let(:start_time) { WorkingHours.advance_to_working_time(Time.new(year, month, 1) - 1.working.day) }
          let(:end_time)   { WorkingHours.return_to_working_time(Time.new(year, month, 1) + 3.working.day) }
          let(:params) { { year: year, month: month } }
          let!(:leave_application) { FactoryGirl.create(:leave_application, :with_leave_time, :approved, :annual, start_time: start_time, end_time: end_time) }
          let!(:leave_application2) { FactoryGirl.create(:leave_application, :with_leave_time, :approved, :personal, user: leave_application.user, start_time: start_time + 5.working.day, end_time: start_time + 7.working.day) }

          context "approved" do
            context "within given range" do
              it "show records on page" do
                expect(subject).to have_http_status :success
                expect(assigns[:users]).to include leave_application.user
                expect(assigns[:users].first.leave_applications).to include leave_application
                expect(assigns[:users].first.leave_applications.leave_hours_within_month(year: year, month: month)).to eq 32
                expect(assigns[:users].first.leave_applications.leave_hours_within_month(year: year, month: month, type: 'personal')).to eq 16
                expect(response.body).not_to match "#{I18n.t("warnings.no_data")}"
              end
            end
          end

          context "not approved" do
            let!(:leave_application) { FactoryGirl.create(:leave_application, :with_leave_time, :annual, start_time: start_time, end_time: end_time) }
            let!(:leave_application2) { FactoryGirl.create(:leave_application, :with_leave_time, :personal, user: leave_application.user, start_time: start_time + 5.working.day, end_time: start_time + 7.working.day) }
            it "should render no data alert" do
              expect(subject).to have_http_status :success
              expect(response.body).to match "#{I18n.t("warnings.no_data")}"
            end
          end
        end

        context "no leave_applications within month" do
          it "should render no data alert" do
            expect(subject).to have_http_status :success
            expect(response.body).to match "#{I18n.t("warnings.no_data")}"
          end
        end
      end
    end
  end
end

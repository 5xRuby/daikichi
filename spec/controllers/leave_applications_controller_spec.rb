# frozen_string_literal: true
require "rails_helper"
RSpec.describe LeaveApplicationsController, type: :controller do
  describe "#cancel" do
    let(:leave_application) { FactoryGirl.create(:leave_application, :approved, :annual, :with_leave_time) }
    let(:params) { { id: leave_application.id } }
    subject { post :cancel, params: params }

    context "not logged in" do
      include_examples "authorization failed"
    end

    shared_examples "cancel rejected" do
      it "leave_application status should remain approved" do
        expect(leave_application.status).to eq "approved"
      end
    end

    shared_examples "cancel successful" do
       it "should be able to cancel leave_application" do
          expect(subject).to have_http_status :redirect
          expect(response).to redirect_to action: :index, params: { status: :pending }
          expect(leave_application.reload.status).to eq "canceled"
       end
    end

    shared_examples "cancel owned leave_application" do
      context "canceling owned leave_application" do
        let(:leave_application) { FactoryGirl.create(:leave_application, :approved, :annual, :with_leave_time, user: controller.current_user) }

        context "approved but already passed" do
          let(:leave_application) { FactoryGirl.create(:leave_application, :approved, :annual, :with_leave_time, :happened, user: controller.current_user) }
          include_examples "cancel rejected"
        end

        context "approved and not yet happened" do
          include_examples "cancel successful"
        end
      end
    end

    context "logged in" do
      login_employee
      include_examples "cancel owned leave_application"

      context "canceling other user's leave_application" do
        include_examples "authorization failed"
        include_examples "cancel rejected"
      end
    end
  end
end

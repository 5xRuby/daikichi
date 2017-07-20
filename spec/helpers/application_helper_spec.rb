# frozen_string_literal: true
require 'rails_helper'

describe ApplicationHelper do
  describe '#hours_to_humanize' do
    let(:params) { 0 }
    subject { helper.hours_to_humanize(params) }

    it 'return `-` if 0 hours' do
      expect(subject).to eq '-'
    end

    context 'hours larger than 0' do
      let(:params) { 10 }
      it 'return humanize working hours' do
        expect(subject).to eq I18n.t('time.humanize_working_hour', days: 1, hours: 2, total: 10)
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Overtime, type: :model do
  let(:manager) { create(:user, :manager) }
  let(:staff) { create(:user, :fulltime) }
  let(:start_time) { Time.zone.local(2019, 1, 1, 0, 0) }
  let(:end_time) { Time.zone.local(2019, 1, 1, 1, 0) }

  describe '#associations' do
    it { is_expected.to have_one(:overtime_pay) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:manager).with_foreign_key(:manager_id) }
  end

  describe 'validation' do
    it 'start_time 必填' do
      record = Overtime.new(end_time: end_time, description: 'xx')
      expect(record).to be_invalid
      expect(record.errors.messages[:start_time].first).to eq I18n.t(
        'activerecord.errors.models.overtime.attributes.start_time.blank'
      )
    end

    it 'end_time 必填' do
      record = Overtime.new(start_time: start_time, description: 'xx')
      expect(record).to be_invalid
      expect(record.errors.messages[:end_time].first).to eq I18n.t(
        'activerecord.errors.models.overtime.attributes.end_time.blank'
      )
    end

    it 'description 必填' do
      record = Overtime.new(start_time: start_time, end_time: end_time)
      expect(record).to be_invalid
      expect(record.errors.messages[:description].first).to eq I18n.t(
        'activerecord.errors.models.overtime.attributes.description.blank'
      )
    end

    it '開始時間應小於結束時間' do
      record = Overtime.new(
        start_time: end_time,
        end_time: start_time,
        description: 'aa'
      )
      expect(record).to be_invalid
      expect(record.errors.messages[:start_time].first).to eq I18n.t(
        'activerecord.errors.models.overtime.attributes.start_time.should_be_earlier'
      )
    end

    it 'hours應為正整數' do
      record = Overtime.new(
        start_time: start_time,
        end_time: start_time + 1.minute,
        description: 'aa'
      )
      expect(record).to be_invalid
      expect(record.errors.messages[:end_time].first).to eq I18n.t(
        'activerecord.errors.models.overtime.attributes.end_time.not_integer'
      )
    end

    it '時段不應重複' do
      url = Rails.application.routes.url_helpers
      record1 = manager.overtimes.create(
        start_time: start_time,
        end_time: end_time + 48.hours,
        description: 'aa'
      )
      record2 = manager.overtimes.new(
        start_time: start_time,
        end_time: end_time + 1.hour,
        description: 'aa'
      )

      expect(record2).to be_invalid
      expect(record2.errors.messages[:base].first).to eq I18n.t(
        'activerecord.errors.models.overtime.attributes.base.time_range_overlapped',
        start_time: record1.start_time.to_formatted_s(:month_date),
        end_time: record1.end_time.to_formatted_s(:month_date),
        link: url.overtime_path(id: record1.id)
      )
    end
  end
end

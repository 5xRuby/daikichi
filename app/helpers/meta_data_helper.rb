# frozen_string_literal: true
module MetaDataHelper
  def page_title
    "#{t(page_title_translation_key, raise: true)} | #{t('misc.app_title')}"
  rescue
    t('misc.app_title')
  end

  def page_title_translation_key
    :"title.#{controller_path}.#{action_name}"
  end
end

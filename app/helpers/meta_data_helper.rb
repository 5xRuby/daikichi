# MetaDataHelper
module MetaDataHelper
  def page_title(append_app_title = false)
    app_title = Settings.metadata.title
    begin
      title = t(page_title_translation_key, raise: true)
      append_app_title ? "#{title} | #{app_title}" : title
    rescue
      app_title
    end
  end

  def page_title_translation_key
    :"title.#{controller_path}.#{action_name}"
  end
end

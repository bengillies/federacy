module PathHelpers
  def self.html_path path_name, *objects
    record = objects.last

    if record.content_type != 'text/x-markdown'
      Rails.application.routes.url_helpers.send path_name, *objects, format: :html
    else
      Rails.application.routes.url_helpers.send path_name, *objects
    end
  end
end

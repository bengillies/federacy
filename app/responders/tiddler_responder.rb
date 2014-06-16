class TiddlerResponder < ActionController::Responder
  def respond
    if should_send_raw?
      @format = raw_type
    end

    super
  end

  # Send the resource body directly with it's decared content type only if there
  # is no explicitly declared format/accept header, and it's a thing that has a
  # content type, and it's content type doesn't render into HTML (i.e. some sort
  # of wikitext, currently only markdown).
  def should_send_raw?
    request.headers["HTTP_ACCEPT"].include?("*/*") &&
      controller.params[:format].nil? &&
      resource.respond_to?(:content_type) &&
      resource.content_type != 'text/x-markdown'
  end

  def raw_type
    if resource.respond_to?(:binary?) && resource.binary?
      'file'
    else
      'data'
    end
  end

  def to_file
    controller.send_file resource.body.path, filename: resource.title,
      type: resource.content_type, disposition: :inline
  end

  def to_data
    controller.send_data resource.body, filename: resource.title,
      type: resource.content_type, disposition: :inline
  end

end

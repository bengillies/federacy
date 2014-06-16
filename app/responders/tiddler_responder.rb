class TiddlerResponder < ActionController::Responder
  def respond
    if should_send_binary?
      @format = 'binary'
    end

    super
  end

  def should_send_binary?
    request.headers["HTTP_ACCEPT"].include?("*/*") &&
      controller.params[:format].nil? &&
      resource.respond_to?(:binary?) && resource.binary?
  end

  def to_binary
    controller.send_file resource.body.path, filename: resource.title,
      type: resource.content_type, disposition: :inline
  end
end

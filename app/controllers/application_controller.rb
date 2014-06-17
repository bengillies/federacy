class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  serialization_scope :view_context

  protected

  def not_found name
    render text: "#{name} Not Found", status: :not_found
  end

  def created type, object, location
    options = { type => object, status => :created, location => location }
    render options
  end

  def no_content
    head :no_content
  end

  def unprocessable_entity
    render text: "Unprocessable Entity", status: :unprocessable_entity
  end
end

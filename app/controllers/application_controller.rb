class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  serialization_scope :view_context

  before_filter :configure_permitted_devise_parameters, if: :devise_controller?

  protected

  def configure_permitted_devise_parameters
    devise_parameter_sanitizer.for(:sign_up) << :name
    devise_parameter_sanitizer.for(:account_update) << :name
    devise_parameter_sanitizer.for(:sign_up) << :icon
    devise_parameter_sanitizer.for(:account_update) << :icon
  end

  #HTTP Status codes

  def not_found name
    render text: "#{name} Not Found", status: :not_found
  end

  def forbidden action, name
    render text: "You cannot #{action} this #{name}", status: :forbidden
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

  # Permissions checking

  %w(tiddler space).each do |object|
    define_method "create_#{object}?" do
      current_user.send("create_#{object}?", @space)
    end
    define_method "edit_#{object}?" do
      current_user.send("edit_#{object}?", instance_variable_get("@#{object}"))
    end
    define_method "delete_#{object}?" do
      current_user.send("delete_#{object}?", instance_variable_get("@#{object}"))
    end
  end
end

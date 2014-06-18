module Filterable
  extend ActiveSupport::Concern

  included do
    has_scope :by_tag, as: :tag, only: :index, type: :array
    has_scope :by_title, as: :title, only: :index
    has_scope :by_creator, as: :creator, only: :index
    has_scope :by_modifier, as: :modifier, only: :index
    has_scope :by_content_type, as: :content_type, only: :index
    has_scope :by_created, as: :created, only: :index
    has_scope :by_modified, as: :modified, only: :index
    has_scope :by_field, as: :field, only: :index, type: :hash
  end

end

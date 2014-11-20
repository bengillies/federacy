class RevisionLinkSerializer < ApplicationSerializer
  attributes :start, :end, :link_type, :link, :tiddler_title, :space_name,
    :user_name,  :from, :to
end

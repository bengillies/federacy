class RevisionLinkSerializer < ApplicationSerializer
  attributes :start, :end, :link_type, :link, :tiddler_title, :space_name,
    :user_name, :from, :to

  def from
    {
      tiddler_id:  object.from.id,
      space_id:    object.from.space.id,
      revision_id: object.revision_id
    }
  end

  def to
    {
      tiddler_id:  object.tiddler_id,
      space_id:    object.space_id,
      revision_id: object.target_id
    }
  end
end

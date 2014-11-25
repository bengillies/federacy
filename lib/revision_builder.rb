class RevisionBuilder

  def initialize tiddler, user, link_builder
    @tiddler = tiddler
    @user = user
    @link_builder = link_builder
  end

  def build attrs
    old_revision = @tiddler.current_revision
    revision_body = revision_type(attrs).build
    revision_body.set_body! attrs

    revision = revision_body.revisions.build(
      title: attrs["title"],
      user_id: @user.id
    )
    add_tags(revision, attrs["tags"])
    add_fields(revision, attrs["fields"])
    @link_builder.create_links(revision, revision_body)
    revision
  end

  def from_previous previous_revision_id, attrs = {}
    old_revision = @tiddler.revisions.find previous_revision_id

    new_attrs = {
      "title"        => old_revision.title,
      "tags"         => old_revision.tags.to_s,
      "fields"       => old_revision.fields,
      "content_type" => old_revision.content_type,
    }.merge(attrs)

    if old_revision.binary?
      new_attrs["file"] ||= old_revision.body
    else
      new_attrs["text"] ||= old_revision.body
    end

    build new_attrs
  end

  def add_tags revision, new_tags
    new_tags = TagList.from_s(new_tags) unless new_tags.respond_to?(:each)
    new_tags.each {|name| revision.revision_tags.build name: name }
    new_tags
  end

  def add_fields revision, new_fields
    return nil unless new_fields.respond_to?(:each)
    new_fields.each {|k, v| revision.revision_fields.build key: k, value: v }
    new_fields
  end

  def revision_type attrs
    if attrs.has_key?("file")
      @tiddler.file_revisions
    else
      @tiddler.text_revisions
    end
  end

end

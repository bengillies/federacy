atom_feed do |feed|
  feed.title "All Revisions for #{@tiddler.title} in #{@space.name}"

  if @revisions.length
    feed.updated @revisions.first.created
  end

  @revisions.each do |revision|
    feed.entry(revision,
      published: revision.created,
      updated: revision.created,
      url: html_path(
        :space_tiddler_revision_path,
        @space, @tiddler, revision)
      ) do |entry|

      entry.title revision.title
      entry.content render_tiddler(revision, content_type: revision.content_type), type: :html
      entry.author do |author|
        author.name(tiddler.modifier.email)
      end
    end
  end
end

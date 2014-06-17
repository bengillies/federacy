atom_feed do |feed|
  feed.title "All Tiddlers in #{@space.name}"

  if @tiddlers.length
    feed.updated @tiddlers.first.modified
  end

  @tiddlers.each do |tiddler|
    feed.entry(tiddler,
      published: tiddler.created,
      updated: tiddler.modified,
      url: html_path(
          :space_tiddler_path, @space, tiddler)
        ) do |entry|

      entry.title tiddler.title
      entry.content render_tiddler(tiddler, content_type: tiddler.content_type), type: :html
    end
  end
end

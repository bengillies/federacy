atom_feed do |feed|
  feed.title "All Spaces"

  if @spaces.length
    feed.updated @spaces.first.updated_at
  end

  @spaces.each do |space|
    feed.entry(space) do |entry|
      entry.title space.name
      entry.content markdown(space.description), type: :html
    end
  end
end

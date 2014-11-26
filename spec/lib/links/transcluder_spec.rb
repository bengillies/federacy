require 'spec_helper'
require 'links/transcluder'

describe Links::Transcluder do

  let(:user) { double("User", name: "Millard Fillmore") }
  let(:tiddlers) { double("tiddlers") }
  let(:tiddler) { double("tiddler") }
  let(:space) do
    double("Space",
      name: "Foo",
      id: 1,
      users: [user],
      tiddlers: tiddlers
    )
  end
  let(:renderer) do
    double("Renderer",
      space: space,
      clone: double('renderer', render_tiddler: tiddler.text),
      render_tiddler: "html content"
    )
  end
  let(:transcluder) do
    Links::Transcluder.new(
      "http://example.com",
      renderer,
      user
    )
  end

  before(:each) do
    allow(Space).to receive(:find).and_return(space)
    allow(Space).to receive(:find_by_name).and_return(space)
    allow(tiddlers).to receive(:find).and_return(tiddler)
    allow(tiddlers).to receive(:by_title).and_return(tiddlers)
    allow(tiddlers).to receive(:first).and_return(tiddler)
  end

  it 'transcludes things' do
    allow(tiddler).to receive_messages(
      id: 1,
      title: 'Qux',
      text: 'lorem ipsum dolor sit amet',
      content_type: 'text/x-markdown'
    )

    html = transcluder.transclude(
      text: "foo\nSTART\n\n<a href=\"/link/here\">Qux</a>\n\nEND\nbar",
      links: [{
        link: '/link/here',
        space_id: 1,
        tiddler_id: 1
      }],
      tokens: { start: 'START', end: 'END' },
      include_revision: false

    )

    expect(html).to eq("foo\n<div class=\"transclusion\">lorem ipsum dolor sit amet</div>\nbar")
  end

  it 'doesn\'t transclude if it can\'t find things' do
    allow(tiddler).to receive_messages(
      id: 1,
      title: 'Qux',
      text: 'lorem ipsum dolor sit amet',
      content_type: 'text/x-markdown'
    )
    allow(tiddlers).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
    html = transcluder.transclude(
      text: "foo\nSTART\n\n<a href=\"/link/here\">Qux</a>\n\nEND\nbar",
      links: [{
        link: '/link/here',
        space_id: 5,
        tiddler_id: 5
      }],
      tokens: { start: 'START', end: 'END' },
      include_revision: false

    )

    expect(html).to eq("foo\n<div class=\"transclusion\">\n\n<a href=\"/link/here\">Qux</a>\n\n</div>\nbar")
  end

  it 'transcludes different content types properly' do
    allow(tiddler).to receive_messages(
      id: 1,
      title: 'Qux',
      text: 'lorem ipsum dolor sit amet',
      content_type: 'image/png'
    )

    html = transcluder.transclude(
      text: "foo\nSTART\n\n<a href=\"/link/here\">Qux</a>\n\nEND\nbar",
      links: [{
        link: '/link/here',
        space_id: 1,
        tiddler_id: 1
      }],
      tokens: { start: 'START', end: 'END' },
      include_revision: false

    )

    expect(renderer.clone).to have_received(:render_tiddler)
      .with(tiddler, content_type: 'image/png')
    expect(html).to eq("foo\n<div class=\"transclusion\">lorem ipsum dolor sit amet</div>\nbar")
  end

  it 'transcludes by name if there are no IDs' do
    allow(tiddler).to receive_messages(
      id: 1,
      title: 'Qux',
      text: 'lorem ipsum dolor sit amet',
      content_type: 'text/x-markdown'
    )

    html = transcluder.transclude(
      text: "foo\nSTART\n\n<a href=\"/link/here\">Qux</a>\n\nEND\nbar",
      links: [{
        link: '/link/here',
        space_name: 'Foo',
        tiddler_title: 'Qux'
      }],
      tokens: { start: 'START', end: 'END' },
      include_revision: false

    )

    expect(html).to eq("foo\n<div class=\"transclusion\">lorem ipsum dolor sit amet</div>\nbar")
  end

  it 'transcludes revisions if it\'s working with revisions' do
    revision = double('Revision',
      id: 1,
      text: "revision text",
      content_type: 'text/plain'
    )
    allow(tiddler).to receive_messages(
      id: 1,
      title: 'Qux',
      text: 'lorem ipsum dolor sit amet',
      content_type: 'text/x-markdown',
      revisions: double('Revisions', find: revision)
    )

    html = transcluder.transclude(
      text: "foo\nSTART\n\n<a href=\"/link/here\">Qux</a>\n\nEND\nbar",
      links: [{
        link: '/link/here',
        space_id: 1,
        tiddler_id: 1,
        target_id: 1
      }],
      tokens: { start: 'START', end: 'END' },
      include_revision: true

    )

    expect(html).to eq("foo\n<div class=\"transclusion\">lorem ipsum dolor sit amet</div>\nbar")
    expect(renderer.clone).to have_received(:render_tiddler)
      .with(revision, content_type: 'text/plain')
  end

end

require 'spec_helper'
require 'renderer'

describe Renderer do

  let(:user) { double("User", name: "Millard Fillmore") }
  let(:tiddlers) { double("tiddlers") }
  let(:view) { double('view', render: "html" ) }
  let(:space) do
    double("Space",
      name: "Foo",
      id: 1,
      users: [user],
      tiddlers: tiddlers
    )
  end
  let(:renderer) do
    Renderer.new(
      user: user,
      space: space,
      view: view,
      root_url: 'http://example.com'
    )
  end

  context 'rendering markdown' do
    it 'renders markdown tiddlers' do
      tiddler = double("Tiddler", text: 'foo [[bar]] baz', links: nil)

      html = renderer.markdown(tiddler.text, tiddler)

      expect(html).to eq("<p>foo <a href=\"/spaces/1/t/bar\">bar</a> baz</p>\n")
    end

    it 'transcludes transclusions' do
      allow(Space).to receive(:find).and_return(space)
      allow(tiddlers).to receive(:find).and_return(double("Tiddler",
        text: "lorem ipsum _dolor_ sit amet",
        links: nil,
        id: 3,
        content_type: 'text/x-markdown'
      ))

      tiddler = double("Tiddler",
        text: "foo\n{{bar}}\nbaz",
        links: [{
          link_type: :transclusion,
          revision_id: 1,
          tiddler_id: 3,
          space_id: 1,
          target_id: 2,
          tiddler_title: "Bar",
          space_name: "Foo",
          title: 'bar',
          start: 4,
          end: 10
      }])

      html = renderer.markdown(tiddler.text, tiddler)

      expect(html).to eq("<p>foo</p>\n\n<div class=\"transclusion\"><p>lorem ipsum <em>dolor</em> sit amet</p>\n</div>\n\n<p>baz</p>\n")
    end

    it 'leaves missing transclusions as links' do
      allow(Space).to receive(:find).and_return(space)
      allow(tiddlers).to receive(:find).and_raise(ActiveRecord::RecordNotFound)

      tiddler = double("Tiddler",
        text: "foo\n{{bar}}\nbaz",
        links: [{
          link_type: :transclusion,
          revision_id: 1,
          tiddler_id: 3,
          space_id: 1,
          target_id: 2,
          tiddler_title: "Bar",
          space_name: "Foo",
          title: 'bar',
          start: 4,
          end: 10
      }])

      html = renderer.markdown(tiddler.text, tiddler)

      expect(html).to eq("<p>foo</p>\n\n<div class=\"transclusion\">\n\n<p><a href=\"/spaces/1/tiddlers/3\">bar</a></p>\n\n</div>\n\n<p>baz</p>\n")
    end

    it 'handles infinite loops while transcluding' do
      allow(Space).to receive(:find).and_return(space)
      tiddler = double("Tiddler",
        id: 3,
        text: "foo\n{{bar}}\nbaz",
        content_type: 'text/x-markdown',
        links: [{
          link_type: :transclusion,
          revision_id: 1,
          tiddler_id: 3,
          space_id: 1,
          target_id: 2,
          tiddler_title: "Bar",
          space_name: "Foo",
          title: 'bar',
          start: 4,
          end: 10
      }])
      allow(tiddlers).to receive(:find).and_return(tiddler)


      html = renderer.markdown(tiddler.text, tiddler)

      expect(html).to eq("<p>foo</p>\n\n<div class=\"transclusion\"><p>foo</p>\n\n<div class=\"transclusion\">\n\n<p><a href=\"/spaces/1/tiddlers/3\">bar</a></p>\n\n</div>\n\n<p>baz</p>\n</div>\n\n<p>baz</p>\n")
    end
  end

  context 'rendering different types of tiddler' do
    it 'markdown tiddlers with the markdown template' do
      tiddler = double('Tiddler',
        title: "Foo",
        content_type: 'text/x-markdown',
        binary?: false
      )

      renderer.render_tiddler tiddler, content_type: 'text/x-markdown'

      expect(view).to have_received(:render)
        .with('shared/renderers/markdown.html.erb', object: tiddler)
    end

    it 'renders plain text tiddlers with the plain text template' do
      tiddler = double('Tiddler',
        title: "Foo",
        content_type: 'text/plain',
        binary?: false
      )

      renderer.render_tiddler tiddler, content_type: 'text/plain'

      expect(view).to have_received(:render)
        .with('shared/renderers/text.html.erb', object: tiddler)
    end

    it 'renders image tiddlers with the image template' do
      tiddler = double('Tiddler',
        title: "Foo",
        content_type: 'image/png',
        binary?: false
      )

      renderer.render_tiddler tiddler, content_type: 'image/png'

      expect(view).to have_received(:render)
        .with('shared/renderers/image.html.erb', object: tiddler)
    end

    it 'lets you override the tiddler content type' do
      tiddler = double('Tiddler',
        title: "Foo",
        content_type: 'text/x-markdown',
        binary?: false
      )

      renderer.render_tiddler tiddler, content_type: 'text/plain'

      expect(view).to have_received(:render)
        .with('shared/renderers/text.html.erb', object: tiddler)
    end

    it 'defaults unknown types to plain text' do
      tiddler = double('Tiddler',
        title: "Foo",
        content_type: 'text/x-wibble',
        binary?: false
      )

      renderer.render_tiddler tiddler, content_type: 'text/x-wibble'

      expect(view).to have_received(:render)
        .with('shared/renderers/text.html.erb', object: tiddler)
    end

    it 'defaults unknown binary tiddlers to binary' do
      tiddler = double('Tiddler',
        title: "Foo",
        content_type: 'application/x-wibble',
        binary?: true
      )

      renderer.render_tiddler tiddler, content_type: 'application/x-wibble'

      expect(view).to have_received(:render)
        .with('shared/renderers/binary.html.erb', object: tiddler)
    end
  end

end

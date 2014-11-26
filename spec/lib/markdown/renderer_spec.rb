require 'spec_helper'
require 'markdown/renderer'

describe Markdown::Renderer do

  let(:tokens) do
    {
      start: 'TRANSCLUSIONSTART',
      end: 'TRANSCLUSIONEND'
    }
  end
  let(:markdown) { Redcarpet::Markdown }
  let(:renderer) { Markdown::Renderer }

  context 'pre existing links available' do
    it 'renders links successfully when they already exist' do
      space = double('Space', name: "Foo")
      tiddler = double('Tiddler',
        text: 'foo [[bar]] baz',
        links: [{
          link_type: :tiddlylink,
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

      html = markdown.new( renderer.new(space: space, tiddler: tiddler, tokens: tokens)).render(tiddler.text)

      expect(html).to eq("<p>foo <a href=\"/spaces/1/tiddlers/3\">bar</a> baz</p>\n")
    end

    it 'replaces multiple links by position' do
      space = double('Space', name: "Foo")
      tiddler = double('Tiddler',
        text: 'foo [[bar]] [[qux]] baz',
        links: [{
          link_type: :tiddlylink,
          revision_id: 1,
          tiddler_id: 3,
          space_id: 1,
          target_id: 2,
          tiddler_title: "Bar",
          space_name: "Foo",
          title: 'bar',
          start: 4,
          end: 10
        }, {
          link_type: :tiddlylink,
          revision_id: 1,
          tiddler_id: 4,
          space_id: 2,
          target_id: 3,
          tiddler_title: "Qux",
          space_name: "Foo",
          title: 'qux',
          start: 12,
          end: 18
        }])

      html = markdown.new( renderer.new(space: space, tiddler: tiddler, tokens: tokens)).render(tiddler.text)

      expect(html).to eq("<p>foo <a href=\"/spaces/1/tiddlers/3\">bar</a> <a href=\"/spaces/2/tiddlers/4\">qux</a> baz</p>\n")
    end

    it 'replaces images' do
      space = double('Space', name: "Foo")
      tiddler = double('Tiddler',
        text: 'foo ![[bar]] baz',
        links: [{
          link_type: :tiddlyimage,
          revision_id: 1,
          tiddler_id: 3,
          space_id: 1,
          target_id: 2,
          tiddler_title: "Bar",
          space_name: "Foo",
          title: 'bar',
          start: 4,
          end: 11
        }])

      html = markdown.new( renderer.new(space: space, tiddler: tiddler, tokens: tokens)).render(tiddler.text)

      expect(html).to eq("<p>foo <img src=\"/spaces/1/tiddlers/3\" alt=\"bar\"> baz</p>\n")
    end

    it 'partially replaces transclusions' do
      space = double('Space', name: "Foo")
      tiddler = double('Tiddler',
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
          end: 11
        }])

      r = renderer.new(space: space, tiddler: tiddler, tokens: tokens)
      html = markdown.new(r).render(tiddler.text)

      expect(html).to eq("<p>foo</p>\n\n<p>TRANSCLUSIONSTART</p>\n\n<p><a href=\"/spaces/1/tiddlers/3\">bar</a></p>\n\n<p>TRANSCLUSIONEND</p>\n\n<p>baz</p>\n")
      expect(r.transclusions).to eq([{
          link_type: "transclusion",
          revision_id: 1,
          tiddler_id: 3,
          space_id: 1,
          target_id: 2,
          tiddler_title: "Bar",
          space_name: "Foo",
          title: 'bar',
          start: 4,
          end: 11,
          link: '/spaces/1/tiddlers/3'
        }])
    end

    it 'handles escaping' do
      space = double('Space', name: "Foo")
      tiddler = double('Tiddler',
        text: 'foo [[b[a]r]] baz',
        links: [{
          link_type: :tiddlylink,
          revision_id: 1,
          tiddler_id: 3,
          space_id: 1,
          target_id: 2,
          tiddler_title: "Bar",
          space_name: "Foo",
          title: 'b[a]r',
          start: 4,
          end: 12
        }])

      html = markdown.new( renderer.new(space: space, tiddler: tiddler, tokens: tokens)).render(tiddler.text)

      expect(html).to eq("<p>foo <a href=\"/spaces/1/tiddlers/3\">b[a]r</a> baz</p>\n")
    end
  end

  context 'pre existing shortlinks available' do
    it 'handles links that do not have IDs associated' do
      space = double('Space', name: "Foo")
      tiddler = double('Tiddler',
        text: 'foo [[bar]] baz',
        links: [{
          link_type: :tiddlylink,
          revision_id: 1,
          tiddler_id: nil,
          space_id: nil,
          target_id: nil,
          tiddler_title: "Bar",
          space_name: "Foo",
          title: 'bar',
          start: 4,
          end: 10
        }])

      html = markdown.new( renderer.new(space: space, tiddler: tiddler, tokens: tokens)).render(tiddler.text)

      expect(html).to eq("<p>foo <a href=\"/s/Foo/Bar\">bar</a> baz</p>\n")
    end

    it 'handles links that do not have a space name' do
      space = double('Space', name: "Foo", id: 2)
      tiddler = double('Tiddler',
        text: 'foo [[bar]] baz',
        links: [{
          link_type: :tiddlylink,
          revision_id: 1,
          tiddler_id: nil,
          space_id: nil,
          target_id: nil,
          tiddler_title: "Bar",
          space_name: nil,
          title: 'bar',
          start: 4,
          end: 10
        }])

      html = markdown.new( renderer.new(space: space, tiddler: tiddler, tokens: tokens)).render(tiddler.text)

      expect(html).to eq("<p>foo <a href=\"/spaces/2/t/Bar\">bar</a> baz</p>\n")
    end

    it 'handles links with a user name involved' do
      space = double('Space', name: "Foo")
      tiddler = double('Tiddler',
        text: 'foo bar@Bob:Foo baz',
        links: [{
          link_type: :tiddlylink,
          revision_id: 1,
          tiddler_id: nil,
          space_id: nil,
          target_id: nil,
          tiddler_title: "bar",
          space_name: "Foo",
          user_name: "Bob",
          title: 'bar',
          start: 4,
          end: 14
        }])

      html = markdown.new( renderer.new(space: space, tiddler: tiddler, tokens: tokens)).render(tiddler.text)

      expect(html).to eq("<p>foo <a href=\"/u/Bob/Foo/bar\">bar</a> baz</p>\n")
    end

    it 'handles links that are shortlinks' do
      space = double('Space', name: "Foo")
      tiddler = double('Tiddler',
        text: 'foo [[bob|/s/Foo/bar]] baz',
        links: [{
          link_type: :tiddlylink,
          link: '/s/foo/bar',
          revision_id: 1,
          tiddler_id: nil,
          space_id: nil,
          target_id: nil,
          tiddler_title: "bar",
          space_name: "Foo",
          user_name: nil,
          title: 'bob',
          start: 4,
          end: 21
        }])

      html = markdown.new( renderer.new(space: space, tiddler: tiddler, tokens: tokens)).render(tiddler.text)

      expect(html).to eq("<p>foo <a href=\"/s/foo/bar\">bob</a> baz</p>\n")
    end

    it 'handles links that are urls' do
      space = double('Space', name: "Foo")
      tiddler = double('Tiddler',
        text: 'foo [[bob|http://foo.com]] baz',
        links: [{
          link_type: :tiddlylink,
          link: 'http://foo.com',
          revision_id: 1,
          tiddler_id: nil,
          space_id: nil,
          target_id: nil,
          tiddler_title: nil,
          space_name: nil,
          user_name: nil,
          title: 'bob',
          start: 4,
          end: 25
        }])

      html = markdown.new( renderer.new(space: space, tiddler: tiddler, tokens: tokens)).render(tiddler.text)

      expect(html).to eq("<p>foo <a href=\"http://foo.com\">bob</a> baz</p>\n")
    end
  end

  context 'linking to revisions' do
    it 'links to the specific revision if it\'s working with revisions' do
      space = double('Space', name: "Foo")
      revision = double('Revision',
        text: 'foo [[bob|foo]] baz',
        links: [{
          link_type: :tiddlylink,
          revision_id: 1,
          tiddler_id: 1,
          space_id: 1,
          target_id: 2,
          tiddler_title: "foo",
          space_name: "bar",
          user_name: nil,
          title: 'bob',
          start: 4,
          end: 14
        }])

      html = markdown.new( renderer.new(space: space, tiddler: revision, tokens: tokens, include_revision: true)).render(revision.text)

      expect(html).to eq("<p>foo <a href=\"/spaces/1/tiddlers/1/revisions/2\">bob</a> baz</p>\n")
    end
  end

  context 'no pre existing links' do
    it 'figures out links on its own if there are no links' do
      space = double('Space', name: 'Foo', id: 1)
      tiddler = double('Tiddler',
        text: "[[foo]] @bar [[baz]]",
        links: nil
      )

      html = markdown.new( renderer.new(space: space, tiddler: tiddler, tokens: tokens)).render(tiddler.text)

      expect(html).to eq("<p><a href=\"/spaces/1/t/foo\">foo</a> <a href=\"/s/bar\">bar</a> <a href=\"/spaces/1/t/baz\">baz</a></p>\n")
    end
  end

  context 'embedded links' do
    it 'handles embedding images inside links' do
      space = double('Space', name: 'Foo', id: 1)
      tiddler = double('Tiddler',
        text: "[[![[foo]]|bar]]",
        links: nil
      )

      html = markdown.new( renderer.new(space: space, tiddler: tiddler, tokens: tokens)).render(tiddler.text)

      expect(html).to eq("<p><a href=\"/spaces/1/t/bar\"><img src=\"/spaces/1/t/foo\" alt=\"foo\"></a></p>\n")
    end
  end

end

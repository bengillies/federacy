require 'spec_helper'
require 'markdown/link_extractor'

describe Markdown::LinkExtractor do

  it 'supports all link types' do
    expect(Markdown::LinkExtractor::LINK_TYPES).to eq(%w(
      transclusion
      tiddler_image
      tiddler_space_link
      space_link
      tiddler_link
      footer_reference
      footer_link
      standard_link
      image_link
      footer_image
    ).map(&:to_sym))
  end

  it 'extracts transclusions' do
    expect(Markdown::LinkExtractor.new("{{{foo@bar:baz}}}").extract_links).to eq([{
      start: 0,
      end: 16,
      link_type: :transclusion,
      tiddler_title: 'foo',
      space_name: 'baz',
      user_name: 'bar',
      title: 'foo'
    }])
  end

  it 'extracts tiddler space links' do
    expect(Markdown::LinkExtractor.new("foo@bar:baz [[foo|bar]]@baz:qux").extract_links)
      .to eq([{
        start: 0,
        end: 10,
        link_type: :tiddlylink,
        tiddler_title: 'foo',
        space_name: 'baz',
        user_name: 'bar',
        title: 'foo'
      },
      {
        start: 12,
        end: 30,
        link_type: :tiddlylink,
        tiddler_title: 'bar',
        space_name: 'qux',
        user_name: 'baz',
        title: 'foo'
      }])
  end

  it 'extracts tiddler links' do
    expect(Markdown::LinkExtractor.new("[[foo]] [[foo|bar]]").extract_links)
      .to eq([{
        start: 0,
        end: 6,
        link_type: :tiddlylink,
        tiddler_title: 'foo',
        space_name: nil,
        user_name: nil,
        link: nil,
        title: 'foo'
      },
      {
        start: 8,
        end: 18,
        link_type: :tiddlylink,
        tiddler_title: 'bar',
        space_name: nil,
        user_name: nil,
        link: nil,
        title: 'foo'
      }])
  end

  it 'extracts space links' do
    expect(Markdown::LinkExtractor.new("@foo @[[foo|bar]] @foo:bar @[[foo|bar:baz]]").extract_links)
      .to eq([{
        start: 0,
        end: 3,
        link_type: :tiddlylink,
        tiddler_title: nil,
        space_name: 'foo',
        user_name: nil,
        title: 'foo'
      },
      {
        start: 5,
        end: 16,
        link_type: :tiddlylink,
        tiddler_title: nil,
        space_name: 'bar',
        user_name: nil,
        title: 'foo'
      },
      {
        start: 18,
        end: 25,
        link_type: :tiddlylink,
        tiddler_title: nil,
        space_name: 'bar',
        user_name: 'foo',
        title: 'bar'
      },
      {
        start: 27,
        end: 42,
        link_type: :tiddlylink,
        tiddler_title: nil,
        space_name: 'baz',
        user_name: 'bar',
        title: 'foo'
      }])
  end

  it 'extracts image links' do
    expect(Markdown::LinkExtractor.new("!foo@bar ![[foo]] ![[foo|bar]]@baz:qux").extract_links)
      .to eq([{
        start: 0,
        end: 7,
        link_type: :tiddlyimage,
        tiddler_title: 'foo',
        space_name: 'bar',
        user_name: nil,
        link: nil,
        title: 'foo'
      },
      {
        start: 9,
        end: 16,
        link_type: :tiddlyimage,
        tiddler_title: 'foo',
        space_name: nil,
        user_name: nil,
        link: nil,
        title: 'foo'
      },
      {
        start: 18,
        end: 37,
        link_type: :tiddlyimage,
        tiddler_title: 'bar',
        space_name: 'qux',
        user_name: 'baz',
        link: nil,
        title: 'foo'
      }])
  end

  it 'extracts embedded image links' do
    expect(Markdown::LinkExtractor.new("{{{!foo@bar:baz}}}\n{{{![[foo]]}}}\n{{{![[foo bar]]@[[baz biz:qux]]}}}").extract_links)
      .to eq([{
        start: 0,
        end: 17,
        link_type: :transclusion,
        tiddler_title: 'foo',
        space_name: 'baz',
        user_name: 'bar',
        title: 'foo'
      },
      {
        start: 19,
        end: 32,
        link_type: :transclusion,
        tiddler_title: 'foo',
        space_name: nil,
        user_name: nil,
        title: 'foo'
      },
      {
        start: 34,
        end: 67,
        link_type: :transclusion,
        tiddler_title: 'foo bar',
        space_name: 'qux',
        user_name: 'baz biz',
        title: 'foo bar'
      }])

    expect(Markdown::LinkExtractor.new("[[![[foo]]@bar|baz]] [[!foo@bar|baz]] [[![[foo]]|bar]]@baz:qux @[[![[foo]]@qux|bar:qux]]").extract_links)
      .to eq([{
        start: 2,
        end: 13,
        link_type: :tiddlyimage,
        tiddler_title: 'foo',
        space_name: 'bar',
        user_name: nil,
        link: nil,
        title: 'foo'
      },
      {
        start: 0,
        end: 19,
        link_type: :tiddlylink,
        tiddler_title: 'baz',
        space_name: nil,
        user_name: nil,
        link: nil,
        title: 'foo'
      },
      {
        start: 23,
        end: 30,
        link_type: :tiddlyimage,
        tiddler_title: 'foo',
        space_name: 'bar',
        user_name: nil,
        link: nil,
        title: 'foo'
      },
      {
        start: 21,
        end: 36,
        link_type: :tiddlylink,
        tiddler_title: 'baz',
        space_name: nil,
        user_name: nil,
        link: nil,
        title: 'foo'
      },
      {
        start: 40,
        end: 47,
        link_type: :tiddlyimage,
        tiddler_title: 'foo',
        space_name: nil,
        user_name: nil,
        link: nil,
        title: 'foo'
      },
      {
        start: 38,
        end: 61,
        link_type: :tiddlylink,
        tiddler_title: 'bar',
        space_name: 'qux',
        user_name: 'baz',
        title: 'foo'
      },
      {
        start: 66,
        end: 77,
        link_type: :tiddlyimage,
        tiddler_title: 'foo',
        space_name: 'qux',
        user_name: nil,
        link: nil,
        title: 'foo'
      },
      {
        start: 63,
        end: 87,
        link_type: :tiddlylink,
        tiddler_title: nil,
        space_name: 'qux',
        user_name: 'bar',
        title: 'foo'
      }])
  end

  it 'handles tiddlylinks to urls instead of tiddlers' do
    expect(Markdown::LinkExtractor.new("[[foo|http://example.com]]").extract_links)
      .to eq([{
        start: 0,
        end: 25,
        link_type: :tiddlylink,
        tiddler_title: nil,
        space_name: nil,
        user_name: nil,
        link: 'http://example.com',
        title: 'foo'
      }])
  end

  it 'handles tiddlyimages to urls instead of tiddlers' do
    expect(Markdown::LinkExtractor.new("![[foo|http://example.com/image.png]]").extract_links)
      .to eq([{
        start: 0,
        end: 36,
        link_type: :tiddlyimage,
        tiddler_title: nil,
        space_name: nil,
        user_name: nil,
        link: 'http://example.com/image.png',
        title: 'foo'
      }])
  end

  it 'extracts markdown links' do
    expect(Markdown::LinkExtractor.new("[foo](bar) [foo](bar \"baz\")").extract_links)
      .to eq([{
        start: 0,
        end: 9,
        link_type: :markdown_link,
        link: 'bar',
        title: 'foo'
      },
      {
        start: 11,
        end: 26,
        link_type: :markdown_link,
        link: 'bar',
        title: 'foo'
      }])
  end

  it 'extracts markdown footer links' do
    expect(Markdown::LinkExtractor.new("[foo][] [foo][bar]\n[foo]: bar\n[bar]: baz").extract_links)
      .to eq([{
        start: 0,
        end: 6,
        link_type: :markdown_link,
        link: 'bar',
        title: 'foo'
      },
      {
        start: 8,
        end: 17,
        link_type: :markdown_link,
        link: 'baz',
        title: 'foo'
      }])
  end

  it 'doesn\'t extract anything if the footer reference doesn\'t exist' do
    expect(Markdown::LinkExtractor.new("[foo][bar]").extract_links).to eq([])
  end

  it 'extracts markdown images' do
    expect(Markdown::LinkExtractor.new("![foo](bar) [![baz](qux)](quux)").extract_links)
      .to eq([{
        start: 0,
        end: 10,
        link_type: :markdown_image,
        link: 'bar',
        title: 'foo'
      },
      {
        start: 13,
        end: 23,
        link_type: :markdown_image,
        link: 'qux',
        title: 'baz'
      },
      {
        start: 12,
        end: 30,
        link_type: :markdown_link,
        link: 'quux',
        title: 'baz'
      }])
  end

  it 'doesn\'t extract links from code blocks' do
    expect(Markdown::LinkExtractor.new('`[foo](bar) final-frontier@space`').extract_links)
      .to eq([])
  end

end

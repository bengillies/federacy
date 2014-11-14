require 'spec_helper'
require 'federacy_markdown_link_extractor'

describe FederacyMarkdownLinkExtractor do

  it 'supports all link types' do
    expect(FederacyMarkdownLinkExtractor::LINK_TYPES).to eq(%w(
      transclusion
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
    expect(FederacyMarkdownLinkExtractor.new("{{{foo@bar:baz}}}").extract_links).to eq([{
      start: 0,
      end: 16,
      link_type: :transclusion,
      tiddler: 'foo',
      space: 'baz',
      user: 'bar',
      title: 'foo'
    }])
  end

  it 'extracts tiddler space links' do
    expect(FederacyMarkdownLinkExtractor.new("foo@bar:baz [[foo|bar]]@baz:qux").extract_links)
      .to eq([{
        start: 0,
        end: 10,
        link_type: :tiddlylink,
        tiddler: 'foo',
        space: 'baz',
        user: 'bar',
        title: 'foo'
      },
      {
        start: 12,
        end: 30,
        link_type: :tiddlylink,
        tiddler: 'bar',
        space: 'qux',
        user: 'baz',
        title: 'foo'
      }])
  end

  it 'extracts tiddler links' do
    expect(FederacyMarkdownLinkExtractor.new("[[foo]] [[foo|bar]]").extract_links)
      .to eq([{
        start: 0,
        end: 6,
        link_type: :tiddlylink,
        tiddler: 'foo',
        space: nil,
        user: nil,
        title: 'foo'
      },
      {
        start: 8,
        end: 18,
        link_type: :tiddlylink,
        tiddler: 'bar',
        space: nil,
        user: nil,
        title: 'foo'
      }])
  end

  it 'extracts space links' do
    expect(FederacyMarkdownLinkExtractor.new("@foo @[[foo|bar]] @foo:bar @[[foo|bar:baz]]").extract_links)
      .to eq([{
        start: 0,
        end: 3,
        link_type: :tiddlylink,
        tiddler: nil,
        space: 'foo',
        user: nil,
        title: 'foo'
      },
      {
        start: 5,
        end: 16,
        link_type: :tiddlylink,
        tiddler: nil,
        space: 'bar',
        user: nil,
        title: 'foo'
      },
      {
        start: 18,
        end: 25,
        link_type: :tiddlylink,
        tiddler: nil,
        space: 'bar',
        user: 'foo',
        title: 'bar'
      },
      {
        start: 27,
        end: 42,
        link_type: :tiddlylink,
        tiddler: nil,
        space: 'baz',
        user: 'bar',
        title: 'foo'
      }])
  end

  it 'extracts markdown links' do
    expect(FederacyMarkdownLinkExtractor.new("[foo](bar) [foo](bar \"baz\")").extract_links)
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
    expect(FederacyMarkdownLinkExtractor.new("[foo][] [foo][bar]\n[foo]: bar\n[bar]: baz").extract_links)
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
    expect(FederacyMarkdownLinkExtractor.new("[foo][bar]").extract_links).to eq([])
  end

  it 'extracts markdown images' do
    expect(FederacyMarkdownLinkExtractor.new("![foo](bar) [![baz](qux)](quux)").extract_links)
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
    expect(FederacyMarkdownLinkExtractor.new('`[foo](bar) final-frontier@space`').extract_links)
      .to eq([])
  end

end

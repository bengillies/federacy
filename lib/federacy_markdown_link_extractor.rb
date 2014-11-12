require 'federacy_markdown_parser'

class FederacyMarkdownLinkExtractor
  attr_reader :raw_output

  # Types of parsed output to recognise:
  #
  # Links:
  #
  # standard_link: { title, link, [title_attr] }
  # standard_link: { title, link, image_link: { title, link }, [title_attr] }
  # standard_link: { title, link, footer_image: { title, reference }, [title_attr] }
  # standard_link: { title, link, footer_image: { title_and_reference }, [title_attr] }
  # footer_link: { title, reference }
  # footer_link: { title_and_reference }
  # footer_link: { image_link: { title, link }, reference }
  # footer_link: { footer_image: { title, reference }, reference }
  # footer_link: { footer_image: { title_and_reference }, reference }
  # image_link: { title, link, [title_attr] }
  # footer_image: { title, reference }
  # tiddler_link: { link, [title] }
  # space_link: { link, [title], [user] }
  # tiddler_space_link: { tiddler_link: { link, [title] }, space_link: { link, [user] } }
  #
  #
  # Footer References:
  #
  # footer_reference: { link, reference, [title_attr] }
  #
  #
  # Transclusions:
  #
  # transclusion: { link }
  # transclusion: { tiddler_link: { link } }
  # transclusion: { tiddler_space_link: { tiddler_link: { link }, space_link: { link, [user] } } }
  #

  LINK_TYPES = %w(
    transclusion
    tiddler_space_link
    space_link
    tiddler_link
    footer_reference
    footer_link
    standard_link
    image_link
    footer_image
  ).map(&:to_sym)

  def initialize markdown
    @parser = FederacyMarkdownParser.new
    @raw_output = @parser.parse markdown
  end



  ##
  # Turn a nested list of elements, only some of which we care about, into a
  # flat list of elements, all of which we care about
  ##
  def flatten
    found = []
    unprocessed = @raw_output.clone

    while unprocessed.length > 0
      atom = unprocessed.shift.clone

      if atom.respond_to? :keys
        atom.except!(*(atom.keys & LINK_TYPES).each do |key|
          found << { type: key, value: atom[key] }
        end)
        atom.values.each {|value| unprocessed << value }
      else
        unprocessed = unprocessed.concat atom
      end
    end

    found
  end

  def references
    flatten.select {|obj| obj[:type] == :footer_reference }
      .reduce({}) do |ref_map, reference|
        ref_map[reference[:value][:reference].to_s] = reference[:value][:link]
        ref_map
      end
  end

  def reference_link ref
    ref, link = references.find {|key, link| key == ref }
    link
  end

  def transform
    flatten.map do |link|
      transformer = "format_#{link[:type].to_s}"
      send transformer, link[:value] if respond_to? transformer
    end.flatten.compact
  end

  def format_transclusion link
    tiddler_space_link = link[:tiddler_link] || {}
    tiddler_link = link[:tiddler_link] || tiddler_space_link[:tiddler_link]
    space_link = (tiddler_space_link && tiddler_space_link[:space_link]) || {}

    {
      link_type: :transclusion,
      tiddler: link[:link] || tiddler_link[:link],
      space: space_link[:link],
      user: space_link[:user]
    }
  end

  def format_tiddler_space_link link
    {
      link_type: :tiddler_link,
      tiddler: link[:tiddler_link][:link],
      space: link[:space_link][:link],
      user: link[:space_link][:user]
    }
  end

  def format_space_link link
    {
      link_type: :space_link,
      tiddler: nil,
      space: link[:link],
      user: link[:user]
    }
  end

  def format_tiddler_link link
    {
      link_type: :tiddler_link,
      tiddler: link[:link],
      space: nil,
      user: nil
    }
  end

  def format_footer_link link
    link_target = reference_link(link[:reference] || link[:title_and_reference])
    links = []

    links << format_image_link(link[:image_link]) if link[:image_link]
    links << format_footer_image(link[:footer_image]) if link[:footer_image]

    if link_target
      links << {
        link_type: :markdown_link,
        link: link_target
      }
    end
  end

# TODO: add titles into link objects; change {tiddler,space_user}_link to tiddlylink

  def format_standard_link link
    links = []

    links << format_image_link(link[:image_link]) if link[:image_link]
    links << format_footer_image(link[:footer_image]) if link[:footer_image]

    links << {
      link_type: :markdown_link,
      link: link[:link]
    }
  end

  def format_image_link link
    {
      link_type: :markdown_image,
      link: link[:link]
    }
  end

  def format_footer_image link
    link_target = reference_link(link[:reference] || link[:title_and_reference])
    if link_target
      {
        link_type: :markdown_image,
        link: link_target
      }
    end
  end

end

require 'markdown/parser'

module Markdown

  class LinkExtractor
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
    # tiddler_image: { [tiddler_link], [tiddler_space_link] }
    # tiddler_link: { link, tiddler_image: { [tiddler_link], [tiddler_space_link] } }
    # tiddler_space_link: { tiddler_link: { link, tiddler_image: { [tiddler_link], [tiddler_space_link] } }, space_link: { link, [user] } }
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
      tiddler_image
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
      @parser = Markdown::Parser.new
      @raw_output = @parser.parse markdown
    end

    def extract_links
      flatten.map do |link|
        transformer = "format_#{link[:type].to_s}"
        send transformer, link[:value] if respond_to? transformer
      end.flatten.compact
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
          atom.values.each {|value| unprocessed << value if value.respond_to? :to_a }
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

    def has_image? link
      return :image_link if link[:image_link]
      return :footer_image if link[:footer_image]
      return :tiddler_image if link[:tiddler_image]
      return :tiddler_image if link[:tiddler_link] && link[:tiddler_link][:tiddler_image]
    end

    def link_pos link
      startPos = link[:at] || link[:image_open] || link[:open]
      startPos &&= startPos.offset
      endPos = link[:close] && link[:close].offset + link[:close].size - 1

      # handle links without special start and end characters, e.g. foo@bar
      unless startPos && endPos
        strPos = link.values.reduce(start: Float::INFINITY, end: 0) do |res, val|
          if val.respond_to?(:offset)
            valStart = val.offset
            valEnd = val.offset + val.size - 1
          else
            valStart, valEnd = link_pos(val)
          end
          {
            start: res[:start] < valStart ? res[:start] : valStart,
            end: res[:end] > valEnd ? res[:end] : valEnd
          }
        end
      end

      [
        startPos || strPos[:start],
        endPos || strPos[:end]
      ]
    end

    def format_transclusion link
      tiddler_image = link[:tiddler_image] || {}
      tiddler_space_link =
        link[:tiddler_space_link] ||
        tiddler_image[:tiddler_space_link] ||
        {}
      tiddler_link =
        link[:tiddler_link] ||
        tiddler_image[:tiddler_link] ||
        tiddler_space_link[:tiddler_link]
      space_link = (tiddler_space_link && tiddler_space_link[:space_link]) || {}
      startPos, endPos = link_pos link

      {
        start: startPos,
        end: endPos,
        link_type: :transclusion,
        tiddler: link[:link] || tiddler_link[:link],
        space: space_link[:link],
        user: space_link[:user],
        title: link[:link] || tiddler_link[:link]
      }
    end

    def format_tiddler_image link
      image_link_type = link[:tiddler_link] ? :tiddler_link : :tiddler_space_link
      image_details = send("format_#{image_link_type}", link[image_link_type]).first
      startPos, endPos = link_pos link

      {
        start: startPos,
        end: endPos,
        link_type: :tiddlyimage,
        tiddler: image_details[:tiddler],
        space: image_details[:space],
        user: image_details[:user],
        title: image_details[:title]
      }
    end

    def format_tiddler_space_link link
      startPos, endPos = link_pos(link)
      links = []
      title = nil

      if img_link = has_image?(link)
        links << img_link = send(
          "format_#{img_link}",
          link[img_link] || link[:tiddler_link][img_link]
        )
        title = img_link[:title]
      end

      links << {
        start: startPos,
        end: endPos,
        link_type: :tiddlylink,
        tiddler: link[:tiddler_link][:link],
        space: link[:space_link][:link],
        user: link[:space_link][:user],
        title: title || link[:tiddler_link][:title] || link[:tiddler_link][:link]
      }
    end

    def format_space_link link
      startPos, endPos = link_pos(link)
      links = []
      title = nil

      if img_link = has_image?(link)
        links << img_link = send("format_#{img_link}", link[img_link])
        title = img_link[:title]
      end

      links << {
        start: startPos,
        end: endPos,
        link_type: :tiddlylink,
        tiddler: nil,
        space: link[:link],
        user: link[:user],
        title: title || link[:title] || link[:link]
      }
    end

    def format_tiddler_link link
      startPos, endPos = link_pos(link)
      links = []
      title = nil

      if img_link = has_image?(link)
        links << img_link = send("format_#{img_link}", link[img_link])
        title = img_link[:title]
      end

      links << {
        start: startPos,
        end: endPos,
        link_type: :tiddlylink,
        tiddler: link[:link],
        space: nil,
        user: nil,
        title: title || link[:title] || link[:link]
      }
    end

    def format_footer_link link
      link_target = reference_link(link[:reference] || link[:title_and_reference])
      img_link = has_image?(link)
      links = []

      links << image = send("format_#{img_link}", link[img_link]) if img_link

      if link_target
        startPos, endPos = link_pos(link)

        links << {
          start: startPos,
          end: endPos,
          link_type: :markdown_link,
          link: link_target,
          title: link[:title] || (image && image[:title]) || link[:title_and_reference]
        }
      end
    end

    def format_standard_link link
      startPos, endPos = link_pos(link)
      img_link = has_image?(link)
      links = []

      links << image = send("format_#{img_link}", link[img_link]) if img_link

      links << {
        start: startPos,
        end: endPos,
        link_type: :markdown_link,
        link: link[:link],
        title: link[:title] || (image && image[:title])
      }
    end

    def format_image_link link
      startPos, endPos = link_pos(link)

      {
        start: startPos,
        end: endPos,
        link_type: :markdown_image,
        link: link[:link],
        title: link[:title]
      }
    end

    def format_footer_image link
      link_target = reference_link(link[:reference] || link[:title_and_reference])
      if link_target
        startPos, endPos = link_pos(link)

        {
          start: startPos,
          end: endPos,
          link_type: :markdown_image,
          link: link_target,
          title: link[:title] || link[:title_and_reference]
        }
      end
    end
  end

end

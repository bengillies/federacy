require 'markdown/link_extractor'

module Markdown

  class Renderer < Redcarpet::Render::HTML
    attr_reader :transclusions

    LINK_MAPPINGS = {
      tiddlylink:   '[%{title}](%{link})',
      tiddlyimage:  '![%{title}](%{link})',
      transclusion: "\n%{start}\n\n[%{title}](%{link})\n\n%{end}\n",
    }

    def initialize render_opts
      @current_space = render_opts[:space]
      @tokens = render_opts[:tokens]
      super
    end

    def preprocess text
      text = text.clone
      links = Markdown::LinkExtractor.new(text).extract_links
      @transclusions = links.select {|link| link[:link_type] == :transclusion }
      replace_links(text, links.select do |link|
        [:tiddlylink, :tiddlyimage, :transclusion].include? link[:link_type]
      end)
    end

    def replace_links text, links
      # reverse order means embedded images can be replaced easily and that
      # replacing links don't upset the predefined link positions
      links.sort! {|a, b| b[:start] <=> a[:start] }
      embedded = nil
      links.each_with_index do |link, index|
        if index < links.length - 1 && link[:start] < links[index + 1][:end]
          embedded = render_link link
        else
          if embedded
            link[:title] = embedded
            embedded = nil
          end
          replace_link text, link
        end
      end
      text
    end

    def replace_link text, link
      text[link[:start]..link[:end]] = render_link(link)
    end

    def resolve_link link
      if link[:user]
        shortlink = "/u/#{encode link[:user]}/#{encode link[:space]}"
      elsif link[:space]
        shortlink =  "/s/#{encode link[:space]}"
      else
        shortlink = "/spaces/#{encode @current_space.id}/t"
      end

      if link[:tiddler]
        shortlink += "/#{encode link[:tiddler]}"
      end

      shortlink
    end

    def render_link link
      # escape brackets so they don't clash with any markdown
      link[:link] = resolve_link(link).gsub(/(\(|\))/, "\\\\\\1")
      link[:title] = link[:title].to_s.gsub(/(\[|\])/, "\\\\\\1")
      link[:start] = @tokens[:start]
      link[:end] = @tokens[:end]

      LINK_MAPPINGS[link[:link_type]] % link
    end

    private

    def encode param
       ERB::Util.url_encode param
    end

  end

end

require_dependency 'markdown/link_extractor'

module Markdown

  class Renderer < Redcarpet::Render::HTML
    attr_reader :transclusions

    LINK_MAPPINGS = {
      "tiddlylink"   =>   '[%{title}](%{link})',
      "tiddlyimage"  =>  '![%{title}](%{link})',
      "transclusion" => "\n%{start}\n\n[%{title}](%{link})\n\n%{end}\n",
    }

    def initialize render_opts
      @current_space = render_opts[:space]
      @tokens = render_opts[:tokens]
      @tiddler = render_opts[:tiddler]
      @links = render_opts[:tiddler] && render_opts[:tiddler].links
      super
    end

    def preprocess text
      text = text.clone
      links = @links && @links.length ? @links : Markdown::LinkExtractor.new(text).extract_links
      links = find_tiddly_style_links(links).as_json.map(&:symbolize_keys)
      text = replace_links(text, links)
      @transclusions = find_transclusions links
      text
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
            link[:embedded] = true
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

    def resolve_shortlink link
      if link[:user_name]
        shortlink = "/u/#{encode link[:user_name]}/#{encode link[:space_name]}"
      elsif link[:space_name]
        shortlink =  "/s/#{encode link[:space_name]}"
      else
        shortlink = "/spaces/#{encode @current_space.id}/t"
      end

      if link[:tiddler_title]
        shortlink += "/#{encode link[:tiddler_title]}"
      end

      shortlink
    end

    def resolve_id_link link
      new_link = "/spaces/#{link[:space_id]}"
      if link[:tiddler_id]
        new_link += "/tiddlers/#{link[:tiddler_id]}"
        if @tiddler && @tiddler.class == Revision
          new_link += "/revisions/#{link[:target_id]}"
        end
      else
        new_link += "/t/#{link[:tiddler_title]}"
      end

      new_link
    end

    def resolve_link link
      if link[:space_id]
        resolve_id_link link
      else
        resolve_shortlink link
      end
    end

    def render_link link
      link[:link] = (link[:link] || resolve_link(link)).gsub(/(\(|\))/, "\\\\\\1")
      # escape brackets so they don't clash with any markdown
      LINK_MAPPINGS[link[:link_type]] % {
        title: (link[:title].gsub(/(\[|\])/, "\\\\\\1") unless link[:embedded]),
        link: link[:link],
        start: @tokens[:start],
        end:   @tokens[:end]
      }
    end

    private

    def encode param
       ERB::Util.url_encode param
    end

    def find_transclusions links
      links.select {|link| link[:link_type] == "transclusion" }
    end

    def find_tiddly_style_links links
      if links.respond_to? :tiddly_style_links
        links.tiddly_style_links
      else
        links.select do |link|
          [:tiddlylink, :tiddlyimage, :transclusion].include? link[:link_type]
        end
      end
    end

  end

end

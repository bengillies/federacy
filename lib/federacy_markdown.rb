# Extend Markdown syntax with extra linking goodness.
#
# Supported extra links are:
#   - [[links to tiddlers in square brackets]]
#   - [[titles of links then|actual link]]
#   - @link-to-space
#   - link-to-tiddler@space
#   - [[link to tiddler]]@space
#   - [[title|link to tiddler]]@space
#   - @user:space
#   - link-to-tiddler@user:space
#   - [[link to tiddler]]@user:space
#   - [[title|link to tiddler]]@user:space
#   - @[[link to space]]
#   - @[[title|link to space]]
#   - link-to-tiddler@[[space]]
#   - [[link to tiddler]]@[[space]]
#   - [[title|link to tiddler]]@[[space]]
#   - @[[user:space]]
#   - @[[title|user:space]]
#   - link-to-tiddler@[[user:space]]
#   - [[link to tiddler]]@[[user:space]]
#   - [[title|link to tiddler]]@[[user:space]]
#
# Supported transclusions are:
#   - {{{link to tiddler}}}
#   - {{{any-other@link:format}}}
#
# Things that don't yet happen:
#   - Recursion isn't handled at all
#   - Transclusions don't currently transclude or verify the syntax properly
#   - The links don't handle multiple names/changing {tiddler,space} title(s) very well
#   - Transclusions, which are block level things, currently are not block level
#   - It does no url encoding

require 'linking'

class FederacyMarkdown < Redcarpet::Render::HTML
  include Linking

  def initialize render_opts
    @current_space = render_opts[:space]
    super
  end

  def preprocess text
    transform_links(text)
  end

  def postprocess text
    transform_transclusions(text)
  end

  def transform_links text
    LINKS.each do |regex, replacer|
      text = text.gsub(regex, replacer % {current_space: @current_space.id})
    end
    text
  end

  def transform_transclusions text
    TRANSCLUSIONS.each do |regex, replacer|
      text = text.gsub(regex, replacer % {current_space: @current_space.id})
    end
    text
  end
end

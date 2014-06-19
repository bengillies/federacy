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
class FederacyMarkdown < Redcarpet::Render::HTML

  LINKS = {
    # local tiddler links
    /(?<=^|[^@])\[\[([^\]\]\|]+)\]\](?=[^@]|$)/ => '[\1](/spaces/%{current_space}/t/\1)',
    /(?<=^|[^@])\[\[([^\|\]\]]+)\|([^\]\]]+)\]\](?=[^@]|$)/ => '[\1](/spaces/%{current_space}/t/\2)',

    # simple space links
    /(?<=^|[^\]\]\w_-])@([\w_-]+)(?=[^:\w_-]+|$)/ => '[\1](/s/\1)',
    /([\w_-]+)@([\w_-]+)(?=[^:\w_-]|$)/ => '[\1](/s/\2/\1)',
    /\[\[([^\]\]\|]+)\]\]@([\w_-]+)(?=[^:\w_-]|$)/ => '[\1](/s/\2/\1)',
    /\[\[([^\|\]\]]+)\|([^\]\]]+)\]\]@([\w_-]+)(?=[^:\w_-]|$)/ => '[\1](/s/\3/\2)',

    # complex space links (i.e. spaces within square brackets)
    /(?<=^|[^\]\]\w_-])@\[\[([^\]\]\|:]+)\]\]/ => '[\1](/s/\1)',
    /(?<=^|[^\]\]\w_-])@\[\[([^\|\]\]]+)\|([^\]\]\|:]+)\]\]/ => '[\1](/s/\2)',
    /([\w_-]+)@\[\[([^\]\]:]+)\]\]/ => '[\1](/s/\2/\1)',
    /\[\[([^\]\]\|]+)\]\]@\[\[([^\]\]:]+)\]\]/ => '[\1](/s/\2/\1)',
    /\[\[([^\|\]\]]+)\|([^\]\]]+)\]\]@\[\[([^\]\]:]+)\]\]/ => '[\1](/s/\3/\2)',

    # space owned by user links
    /(?<=^|[^\]\]\w_-])@([^:\[\[\]\]]+):([\w_-]+)/ => '[\2](/u/\1/\2)',
    /([\w_-]+)@([^:\[\[\]\]]+):([\w_-]+)/ => '[\1](/u/\2/\3/\1)',
    /\[\[([^\]\]\|]+)\]\]@([^:\[\[\]\]]+):([\w_-]+)/ => '[\1](/u/\2/\3/\1)',
    /\[\[([^\|\]\]]+)\|([^\]\]]+)\]\]@([^:\[\[\]\]]+):([\w_-]+)/ => '[\1 by \3](/s/\4/\2)',

    # complex space owned by user links (i.e. user:space within square brackets)
    /(?<=^|[^\]\]\w_-])@\[\[([^:\|\]\]]+):([^\]\]]+)\]\]/ => '[\2](/u/\1/\2)',
    /(?<=^|[^\]\]\w_-])@\[\[([^\|\]\]]+)\|([^:\]\]]+):([^\]\]\|]+)\]\]/ => '[\1](/u/\2/\3)',
    /([\w_-]+)@\[\[([^:\]\]]+):([^\]\]]+)\]\]/ => '[\1](/u/\2/\3/\1)',
    /\[\[([^\]\]\|]+)\]\]@\[\[([^:\]\]]+):([^\]\]]+)\]\]/ => '[\1](/u/\2/\3/\1)',
    /\[\[([^\|\]\]]+)\|([^\]\]]+)\]\]@\[\[([^:\]\]]+):([^\]\]]+)\]\]/ => '[\1](/u/\3/\4/\2)'
  }

  TRANSCLUSIONS = {
    /\{\{\{([^\}\}\}<>]+)\}\}\}/ => '<div class="transclusion"><a href="/spaces/%{current_space}/t/\1">\1</a></div>',
    /\{\{\{((?:<|>|[^\}\}\}])+)\}\}\}/ => '<div class="transclusion">\1</div>'
  }

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

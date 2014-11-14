class FederacyMarkdownParser < Parslet::Parser

  ##
  # Types of things to match inside a text block line
  ##
  rule(:sym) do
    inline_code_block |
    tiddlylink |
    markdown_link |
    char
  end

  ##
  # Types of line
  ##
  rule(:line) do
    code_block |
    transclusion |
    footer_reference |
    text_line
  end

  ##
  # Types of block
  #
  # There is more than this in markdown, but we only care about a few as we only
  # need to extract links from them
  ##
  rule(:block) do
    code_block |
    transclusion |
    text_block |
    new_line
  end

  ##
  # TiddlyLinks
  #
  # In addition to normal markdown links, supported extra links are:
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
  ##
  rule(:link_open) { str('[[').as(:open) }
  rule(:link_close) { str(']]').as(:close) }
  rule(:link_title_separator) { str('|') }
  rule(:link_user_separator) { str(':') }
  rule(:space_symbol) { str('@').as(:at) }

  rule(:link_title) do
    (
      link_title_separator.absent? >> eol?.absent? >> link_close.absent? >> any
    ).repeat(1).as(:title) >>
    link_title_separator
  end

  rule(:link_body_simple) do
    (link_close.absent? >> eol?.absent? >> any).repeat(1).as(:link)
  end
  rule(:link_body_with_title) do
    link_title >> link_body_simple
  end
  rule(:tiddler_link_body) do
    link_body_with_title |
    link_body_simple
  end
  rule(:tiddler_link) do
    (
      link_open >>
      tiddler_link_body >>
      link_close
    ).as(:tiddler_link)
  end

  rule(:link_user_word) do
    (
      whitespace.absent? >>
      link_user_separator.absent? >>
      any
    ).repeat(1).as(:user) >>
    link_user_separator
  end
  rule(:link_user_body) do
    (
      link_user_separator.absent? >>
      eol?.absent? >>
      link_close.absent? >>
      any
    ).repeat(1).as(:user) >>
    link_user_separator
  end

  rule(:link_word) do
    (whitespace.absent? >> any).repeat(1).as(:link)
  end

  rule(:space_link_body) do
    link_open >> link_title >> link_user_body >> link_body_simple >> link_close |
    link_open >> link_title >> link_body_simple >> link_close |
    link_open >> link_user_body >> link_body_simple >> link_close |
    link_open >> link_body_simple >> link_close |
    link_user_word >> link_word |
    link_word
  end
  rule(:space_link) do
    (space_symbol >> space_link_body).as(:space_link)
  end


  rule(:tiddler_link_unbracketed) do
    (
      (space_symbol.absent? >> whitespace.absent? >> any).repeat(1).as(:link)
    ).as(:tiddler_link)
  end

  rule(:tiddler_space_link) do
    ((tiddler_link | tiddler_link_unbracketed) >> space_link).as(:tiddler_space_link)
  end

  rule(:tiddlylink) do
    tiddler_space_link |
    tiddler_link |
    space_link
  end

  ##
  # Markdown Links
  #
  # Standard links, images and links in footers
  ##

  rule(:square_open) { str('[') }
  rule(:square_close) { str(']') }
  rule(:bracket_open) { str('(') }
  rule(:bracket_close) { str(')') }
  rule(:exclamation_mark) { str('!') }

  rule(:square_body) do
    (square_close.absent? >> image_link.absent? >> any).repeat(1)
  end
  rule(:square_link) do
    square_open.as(:open) >> square_body.as(:title) >> square_close >> str(' ').maybe
  end
  rule(:bracket_body_link_only) do
    (bracket_close.absent? >> any).repeat(1).as(:link)
  end
  rule(:bracket_body_with_title_double_quote) do
    (
      (
        bracket_close.absent? >> (
          match("\s").repeat(1) >> str('"')
        ).absent? >> any
      ).repeat(1).as(:link) >>
      match("\s").repeat(1) >> str('"') >>
      (str('"').absent? >> any).repeat(1).as(:title_attr) >>
      str('"')
    )
  end
  rule(:bracket_body_with_title_single_quote) do
    (
      (
        bracket_close.absent? >> (
          match("\s").repeat(1) >> str("'")
        ).absent? >> any
      ).repeat(1).as(:link) >>
      match("\s").repeat(1) >> str("'") >>
      (str("'").absent? >> any).repeat(1).as(:title_attr) >>
      str("'")
    )
  end
  rule(:bracket_body_with_title) do
    bracket_body_with_title_double_quote | bracket_body_with_title_single_quote
  end
  rule(:bracket_body) do
    bracket_body_with_title | bracket_body_link_only
  end
  rule(:bracket_section) do
    bracket_open >> bracket_body >> bracket_close.as(:close)
  end
  rule(:markdown_base_link) do
    square_link >> bracket_section
  end
  rule(:standard_reference_base) do
    square_open.as(:open) >> square_body.as(:title) >> square_close >>
    match("\s").repeat >>
    square_open >> square_body.as(:reference) >> square_close.as(:close)
  end

  rule(:simple_reference_base) do
    square_open.as(:open) >>
    square_body.as(:title_and_reference) >>
    (square_close >> (match("\s").repeat >> str('[]')).maybe).as(:close)
  end
  rule(:standard_image) do
    (exclamation_mark.as(:image_open) >> markdown_base_link).as(:image_link)
  end
  rule(:footer_image) do
    (
      exclamation_mark.as(:image_open) >>
      (standard_reference_base | simple_reference_base)
    ).as(:footer_image)
  end
  rule(:square_with_image) do
    square_open.as(:open) >> image_link >> square_close >> str(' ').maybe
  end

  rule(:standard_link) do
    (
      (square_with_image >> bracket_section) |
      markdown_base_link
    ).as(:standard_link)
  end

  rule(:image_link) do
    standard_image |
    footer_image >> bracket_section.absent?
  end

  rule(:footer_link) do
    (
      (
        square_with_image >> match("\s").repeat >>
        square_open >> square_body.as(:reference) >> square_close.as(:close)
      ) |
      standard_reference_base |
      simple_reference_base
    ).as(:footer_link)
  end

  rule(:markdown_link) do
    image_link |
    standard_link |
    footer_link
  end

  ##
  # References that footer_links point to
  ##
  rule(:footer_separator) { str(':') >> match("\s").maybe }
  rule(:angle_open) { str('<') }
  rule(:angle_close) { str('>') }
  rule(:angle_body) { (angle_close.absent? >> eol?.absent? >> any).repeat(1) }

  rule(:footer_reference_start) do
    square_open >> square_body.as(:reference) >> square_close >>
    footer_separator
  end

  rule(:footer_reference_title_double_quote) do
    whitespace.repeat >>
    str('"') >> (str('"').absent? >> any).repeat(1).as(:title_attr) >>
    str('"')
  end

  rule(:footer_reference_title_single_quote) do
    whitespace.repeat >>
    str("'") >> (str("'").absent? >> any).repeat(1).as(:title_attr) >>
    str("'")
  end

  rule(:footer_reference_title_bracket) do
    whitespace.repeat >>
    str('(') >> (str(')').absent? >> any).repeat(1).as(:title_attr) >>
    str(')')
  end

  rule(:footer_reference_title) do
    footer_reference_title_double_quote |
    footer_reference_title_single_quote |
    footer_reference_title_bracket
  end

  rule(:footer_reference_with_angles) do
    footer_reference_start >>
    angle_open >> angle_body.as(:link) >> angle_close >>
    footer_reference_title.maybe
  end
  rule(:footer_reference_without_angles_with_title_double_quote) do
    footer_reference_start >>
    (
      (
        match("\s").repeat(1) >> str('"')
      ).absent? >> eol?.absent? >> any
    ).repeat(1).as(:link) >>
    footer_reference_title_double_quote
  end
  rule(:footer_reference_without_angles_with_title_single_quote) do
    footer_reference_start >>
    (
      (
        match("\s").repeat(1) >> str("'")
      ).absent? >> eol?.absent? >> any
    ).repeat(1).as(:link) >>
    footer_reference_title_single_quote
  end
  rule(:footer_reference_without_angles_with_title_bracket) do
    footer_reference_start >>
    (
      (
        match("\s").repeat(1) >> str('(')
      ).absent? >> eol?.absent? >> any
    ).repeat(1).as(:link) >>
    footer_reference_title_bracket
  end
  rule(:footer_reference_without_angles_with_title) do
    footer_reference_without_angles_with_title_double_quote |
    footer_reference_without_angles_with_title_single_quote |
    footer_reference_without_angles_with_title_bracket
  end

  rule(:footer_reference_without_angles) do
    footer_reference_start >> (eol?.absent? >> any).repeat(1).as(:link)
  end

  rule(:footer_reference) do
    (
      footer_reference_with_angles |
      footer_reference_without_angles_with_title |
      footer_reference_without_angles
    ).as(:footer_reference) >> eol?
  end

  ##
  # Transclusions
  #
  # A transclusion sits at the block level and contains a tiddler to transclude
  #
  # e.g.:
  #
  # {{{My Tiddler}}}
  #
  # {{{[[Abraham Lincoln]]@jon-wilkes-booth:people-to-kill}}}
  ##

  rule(:space_link_insude_transclusion) do
    (
      space_symbol >>
      (
        (
          link_user_separator.absent? >>
          link_open.absent? >>
          eol?.absent? >>
          transclusion_end.absent? >>
          any
        ).repeat(1).as(:user) >>
        link_user_separator
      ).maybe >>
      (
        whitespace.absent? >>
        transclusion_end.absent? >>
        link_open.absent? >>
        any
      ).repeat(1).as(:link)
    ).as(:space_link)
  end
  rule(:tiddlylink_inside_transclusion) do
    # handle tiddlylinks where the user/space name isn't enclosed in square brackets
    (
      (tiddler_link | tiddler_link_unbracketed) >>
      space_link_insude_transclusion
    ).as(:tiddler_space_link) |
    space_link_insude_transclusion.as(:space_link)
  end

  rule(:transclusion_start) { str('{{{').as(:open) }
  rule(:transclusion_end) { str('}}}').as(:close) }
  rule(:transclusion_tiddler) do
    tiddlylink_inside_transclusion |
    tiddlylink |
    (transclusion_end.absent? >> eol?.absent? >> any).repeat(1).as(:link)
  end
  rule(:transclusion) do
    (
      transclusion_start >>
      transclusion_tiddler >>
      transclusion_end >> eol?
    ).as(:transclusion)
  end

  ##
  # Text block definition
  ##
  rule(:char) { (eol?.absent? >> any) }
  rule(:text) { sym.repeat(1).as(:text) }
  rule(:text_line) { text >> eol? }
  rule(:text_block) { (line.repeat(1) >> eol?).as(:block) }


  ##
  # Code definitions
  #
  # We need to match these as things that look like links inside code blocks
  # aren't really links
  ##
  rule(:backtick) { str('`') }
  rule(:backticks) { backtick >> backtick >> backtick }
  rule(:tilde) { str('~') }
  rule(:tildes) { tilde >> tilde >> tilde }
  rule(:code_tab) { str("\t") | str("    ") }
  rule(:same_line?) { (new_line.absent? >> any).repeat(0) }

  rule(:inline_code?) { (backtick.absent? >> any).repeat(1) }
  rule(:inline_code_block_unquoted) do
    backtick >> inline_code? >> backtick
  end
  rule(:inline_code_block_quoted) do
    backtick.repeat(1).capture(:backticks) >>
    dynamic do |source, context|
      (str(context.captures[:backticks]).absent? >> any).repeat(0) >>
      str(context.captures[:backticks])
    end
  end
  rule(:inline_code_block) do
    (inline_code_block_unquoted | inline_code_block_quoted).as(:inline_code)
  end

  rule(:code_block_backtick) do
    backticks >> same_line? >> new_line >>
    ((new_line >> backticks >> eol?).absent? >> any).repeat >>
    (new_line >> backticks >> eol? | eof?)
  end
  rule(:code_block_tilde) do
      tildes >> same_line? >> new_line >>
      ((new_line >> tildes >> eol?).absent? >> any).repeat >>
      (new_line >> tildes >> eol? | eof?)
  end
  rule(:code_block_whitespace_sof) do
    dynamic do |source, context|
      if source.pos.charpos == 0
        match('.').present?
      else
        match('.').absent?
      end
    end >>
    (code_tab >> same_line? >> new_line.maybe).repeat(1)
  end
  rule(:code_block_whitespace_newline) do
    match("\s").repeat >> new_line >>
    (code_tab >> same_line? >> new_line.maybe).repeat(1)
  end
  rule(:code_block_whitespace) do
    code_block_whitespace_newline | code_block_whitespace_sof
  end
  rule(:code_block) do
    (
      code_block_backtick |
      code_block_tilde |
      code_block_whitespace
    ).as(:code_block)
  end


  ##
  # utility definitions
  ##
  rule(:whitespace) { match("\s") | new_line }
  rule(:new_line) { (str("\r").maybe >> str("\n")) }
  rule(:eof?) { any.absent? }
  rule(:eol?) { new_line | eof? }

  ##
  # Entry point of parser
  ##
  rule(:document) do
    block.repeat
  end
  root(:document)


end

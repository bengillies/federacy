class FederacyMarkdownParser < Parslet::Parser

  ##
  # Types of things to match inside a text block line
  ##
  rule(:sym) {
    inline_code_block |
    tiddlylink |
    markdown_link |
    char
  }

  ##
  # Types of line
  ##
  rule(:line) {
    code_block |
    transclusion |
    footer_reference |
    text_line
  }

  ##
  # Types of block
  #
  # There is more than this in markdown, but we only care about a few as we only
  # need to extract links from them
  ##
  rule(:block) {
     code_block |
     transclusion |
     text_block |
     new_line
  }

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
  rule(:link_open) { str('[[') }
  rule(:link_close) { str(']]') }
  rule(:link_title_separator) { str('|') }
  rule(:link_user_separator) { str(':') }
  rule(:space_symbol) { str('@') }

  rule(:link_body_simple) {
    (link_close.absent? >> eol?.absent? >> any).repeat(1).as(:link)
  }
  rule(:link_body_with_title) {
    (
      link_title_separator.absent? >> eol?.absent? >> any
    ).repeat(1).as(:title) >>
    link_title_separator >>
    link_body_simple
  }
  rule(:tiddler_link_body) {
    link_body_with_title |
    link_body_simple
  }
  rule(:tiddler_link) {
    (
      link_open >>
      tiddler_link_body >>
      link_close
    ).as(:tiddler_link)
  }

  rule(:link_user_word) {
    (
      whitespace.absent? >>
      link_user_separator.absent? >>
      any
    ).repeat(1).as(:user) >>
    link_user_separator
  }
  rule(:link_user_body) {
    (link_user_separator.absent? >> eol?.absent? >> any).repeat(1).as(:user) >>
    link_user_separator
  }

  rule(:link_word) {
    (whitespace.absent? >> any).repeat(1).as(:link)
  }

  rule(:space_link_body) {
    link_open >> link_user_body >> link_body_simple >> link_close |
    link_open >> link_body_simple >> link_close |
    link_user_word >> link_word |
    link_word
  }
  rule(:space_link) {
    (space_symbol >> space_link_body).as(:space_link)
  }

  rule(:tiddler_space_link) {
    (tiddler_link >> space_link).as(:tiddler_space_link)
  }

  rule(:tiddlylink) {
    tiddler_space_link |
    tiddler_link |
    space_link
  }

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

  rule(:square_body) { (square_close.absent? >> any).repeat(1) }
  rule(:square_link) { square_open >> square_body.as(:title) >> square_close }
  rule(:bracket_body_link_only) {
    (bracket_close.absent? >> any).repeat(1).as(:link)
  }
  rule(:bracket_body_with_title) {
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
  }
  rule(:bracket_body) {
    bracket_body_with_title | bracket_body_link_only
  }
  rule(:bracket_section) {
    bracket_open >> bracket_body >> bracket_close
  }
  rule(:markdown_base_link) {
    square_link >> bracket_section
  }
  rule(:standard_reference_base) {
    square_open >> square_body.as(:title) >> square_close >>
    match("\s").repeat >>
    square_open >> square_body.as(:reference) >> square_close
  }

  rule(:simple_reference_base) {
    square_open >> square_body.as(:title_and_reference) >> square_close
  }
  rule(:standard_image) {
    (exclamation_mark >> markdown_base_link).as(:image_link)
  }
  rule(:standard_image_with_title) {
    (exclamation_mark >> square_link >> bracket_body_with_title).as(:image_link)
  }
  rule(:footer_image) {
    exclamation_mark >>
    (standard_reference_base | simple_reference_base).as(:footer_image)
  }
  rule(:square_with_image) {
    square_open >> image_link >> square_close
  }

  rule(:standard_link) {
    (
      (square_with_image >> bracket_section) |
      markdown_base_link
    ).as(:standard_link)
  }

  rule(:image_link) {
    standard_image |
    footer_image >> bracket_section.absent? |
    standard_image_with_title
  }

  rule(:footer_link) {
    (
      (
        square_with_image >> match("\s").repeat >>
        square_open >> square_body.as(:reference) >> square_close
      ) |
      standard_reference_base |
      square_with_image |
      simple_reference_base
    ).as(:footer_link)
  }

  rule(:markdown_link) {
    image_link |
    standard_link |
    footer_link
  }

  ##
  # References that footer_links point to
  ##
  rule(:footer_separator) { str(':') >> match("\s").maybe }
  rule(:angle_open) { str('<') }
  rule(:angle_close) { str('>') }
  rule(:angle_body) { (angle_close.absent? >> any).repeat(1) }

  rule(:footer_reference_start) {
    square_open >> square_body.as(:reference) >> square_close >>
    footer_separator
  }

  rule(:footer_reference_with_angles) {
    footer_reference_start >>
    angle_open >> angle_body.as(:link) >> angle_close >> match("\s").repeat >> (
      str('"') >> (str('"').absent? >> any).repeat(1).as(:title_attr) >>
      str('"')
    ).maybe
  }
  rule(:footer_reference_without_angles_with_title) {
    footer_reference_start >>

          match("\s").repeat(1) >> str('"')
    (
      (
        match("\s").repeat(1) >> str('"')
      ).absent? >> any
    ).repeat(1).as(:link) >> match("\s").repeat(1) >>
    str('"') >>
    (str('"').absent? >> any).repeat(1).as(:title_attr) >>
    str('"')
  }

  rule(:footer_reference_without_angles) {
    footer_reference_start >> (eol?.absent? >> any).repeat(1).as(:link)
  }

  rule(:footer_reference) {
    (
      footer_reference_with_angles |
      footer_reference_without_angles_with_title |
      footer_reference_without_angles
    ).as(:footer_reference) >> eol?
  }

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
  rule(:transclusion_start) { str('{{{') }
  rule(:transclusion_end) { str('}}}') }
  rule(:transclusion_tiddler) {
    tiddlylink |
    (transclusion_end.absent? >> eol?.absent? >> any).repeat(1).as(:link)
  }
  rule(:transclusion) {
    (
      transclusion_start >>
      transclusion_tiddler >>
      transclusion_end >> eol? >> eol?
    ).as(:transclusion)
  }

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
  rule(:code_delim) { str('`') }
  rule(:code_block_delim) { code_delim >> code_delim >> code_delim }

  rule(:inline_code?) { (code_delim.absent? >> any).repeat }
  rule(:inline_code_block) {
    (code_delim >> (code_delim | inline_code? >> code_delim)).as(:inline_code)
  }

  rule(:code?) { (code_block_end.absent? >> any).repeat }
  rule(:code_block_start) {
    code_block_delim >> (new_line.absent? >> any).repeat(0) >> new_line
  }
  rule(:code_block_end) { new_line >> code_block_delim >> eol? }
  rule(:code_block) {
    (code_block_start >> code? >> code_block_end).as(:code_block)
  }


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
  rule(:document) {
    block.repeat
  }
  root(:document)


end

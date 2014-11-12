require 'spec_helper'
require 'federacy_markdown_parser'

describe FederacyMarkdownParser do

  let(:parser) { FederacyMarkdownParser.new }

  describe 'standard markdown links' do
    it 'should parse standard markdown links' do
      expect(parser.parse("Foo bar [title here](/link/here)")).to contain_parsed_output({
        standard_link: { title: 'title here', link: '/link/here' }
      })

      expect(parser.parse("[title here](/link/here)")).to contain_parsed_output({
        standard_link: { title: 'title here', link: '/link/here' }
      })

      expect(parser.parse("[title here](/link/here) Foo bar")).to contain_parsed_output({
        standard_link: { title: 'title here', link: '/link/here' }
      })
    end

    it 'should support title attributes' do
      expect(parser.parse("[title here](/link/here \"alt\")")).to contain_parsed_output({
        standard_link: { title: 'title here', link: '/link/here', title_attr: 'alt' }
      })

      expect(parser.parse("[title here](/link/here 'alt')")).to contain_parsed_output({
        standard_link: { title: 'title here', link: '/link/here', title_attr: 'alt' }
      })
    end

    it 'should support image links' do
      expect(parser.parse("[![img](/img/link)](/link/here 'alt')")).to contain_parsed_output({
        standard_link: {
          image_link: { title: 'img', link: '/img/link' },
          link: '/link/here',
          title_attr: 'alt'
        }
      })

      expect(
        parser.parse("[![img][ref]](/link/here 'alt')\n[ref]: /img/link")
      ).to contain_parsed_output({
        standard_link: {
          footer_image: { title: 'img', reference: 'ref' },
          link: '/link/here',
          title_attr: 'alt'
        },
        footer_reference: { reference: 'ref', link: '/img/link' }
      })

      expect(
        parser.parse("[![imgref]](/link/here 'alt')\n[imgref]: /img/link")
      ).to contain_parsed_output({
        standard_link: {
          footer_image: { title_and_reference: 'imgref' },
          link: '/link/here',
          title_attr: 'alt'
        },
        footer_reference: { reference: 'imgref', link: '/img/link' }
      })
    end
  end

  describe 'footer links' do
    it 'should parse standard links in footer reference format' do
      expect(
        parser.parse("[title here][ref] Foo bar \n\n[ref]: /link/here")
      ).to contain_parsed_output({
        footer_link: { title: 'title here', reference: 'ref' },
        footer_reference: { link: '/link/here', reference: 'ref' }
      })

      expect(
        parser.parse("[title here]   [ref] Foo bar \n\n[ref]: /link/here")
      ).to contain_parsed_output({
        footer_link: { title: 'title here', reference: 'ref' },
        footer_reference: { link: '/link/here', reference: 'ref' }
      })

      expect(
        parser.parse("[ref] Foo bar \n\n[ref]: /link/here")
      ).to contain_parsed_output({
        footer_link: { title_and_reference: 'ref' },
        footer_reference: { link: '/link/here', reference: 'ref' }
      })

      expect(
        parser.parse("[ref] Foo bar \n\n[ref]: </link/here>")
      ).to contain_parsed_output({
        footer_link: { title_and_reference: 'ref' },
        footer_reference: { link: '/link/here', reference: 'ref' }
      })

      expect(
        parser.parse("[ref][] Foo bar \n\n[ref]: /link/here")
      ).to contain_parsed_output({
        footer_link: { title_and_reference: 'ref' },
        footer_reference: { link: '/link/here', reference: 'ref' }
      })
    end

    it 'should support title attributes' do
      expect(
        parser.parse("[ref] Foo bar \n\n[ref]: /link/here \"alt\"")
      ).to contain_parsed_output({
        footer_link: { title_and_reference: 'ref' },
        footer_reference: { link: '/link/here', reference: 'ref', title_attr: 'alt' }
      })

      expect(
        parser.parse("[ref] Foo bar \n\n[ref]: /link/here 'alt'")
      ).to contain_parsed_output({
        footer_link: { title_and_reference: 'ref' },
        footer_reference: { link: '/link/here', reference: 'ref', title_attr: 'alt' }
      })

      expect(
        parser.parse("[ref] Foo bar \n\n[ref]: /link/here (alt)")
      ).to contain_parsed_output({
        footer_link: { title_and_reference: 'ref' },
        footer_reference: { link: '/link/here', reference: 'ref', title_attr: 'alt' }
      })

      expect(
        parser.parse("[ref] Foo bar \n\n[ref]: /link/here\n   \"alt\"")
      ).to contain_parsed_output({
        footer_link: { title_and_reference: 'ref' },
        footer_reference: { link: '/link/here', reference: 'ref', title_attr: 'alt' }
      })

      expect(
        parser.parse("[ref] Foo bar \n\n[ref]: </link/here>   \"alt\"")
      ).to contain_parsed_output({
        footer_link: { title_and_reference: 'ref' },
        footer_reference: { link: '/link/here', reference: 'ref', title_attr: 'alt' }
      })
    end

    it 'should support image links' do
      expect(
        parser.parse("[![img]][ref] Foo bar \n\n[ref]: </link/here>   \"alt\"\n[img]: /img/link")
      ).to contain_parsed_output({
        footer_link: { footer_image: { title_and_reference: 'img' }, reference: 'ref' },
        footer_reference: [
          { link: '/link/here', reference: 'ref', title_attr: 'alt' },
          { link: '/img/link', reference: 'img' }
        ]
      })

      expect(
        parser.parse("[![img](/img/link)][ref] Foo bar \n\n[ref]: </link/here>   \"alt\"")
      ).to contain_parsed_output({
        footer_link: { image_link: { title: 'img', link: '/img/link' }, reference: 'ref' },
        footer_reference: { link: '/link/here', reference: 'ref', title_attr: 'alt' }
      })
    end
  end

  describe 'images' do
    it 'should support regular images' do
      expect(parser.parse("![img](/img/link)")).to contain_parsed_output({
        image_link: { title: 'img', link: '/img/link' }
      })
    end

    it 'should support images with title attributes' do
      expect(parser.parse("![img](/img/link \"alt\")")).to contain_parsed_output({
        image_link: { title: 'img', link: '/img/link', title_attr: 'alt' }
      })

      expect(parser.parse("![img](/img/link 'alt')")).to contain_parsed_output({
        image_link: { title: 'img', link: '/img/link', title_attr: 'alt' }
      })
    end

    it 'should support images by reference' do
      expect(parser.parse("![img][ref]\n[ref]: /img/link 'alt'")).to contain_parsed_output({
        footer_image: { title: 'img', reference: 'ref' },
        footer_reference: { link: '/img/link', title_attr: 'alt', reference: 'ref' }
      })
    end
  end

  describe 'code blocks' do
    it 'should recognise code blocks' do
      expect(parser.parse("```\nfoo\n```")).to contain_parsed_output({
        code_block: "```\nfoo\n```"
      })

      expect(parser.parse("```code_type\nfoo\n```")).to contain_parsed_output({
        code_block: "```code_type\nfoo\n```"
      })

      expect(parser.parse("~~~\nfoo\n~~~")).to contain_parsed_output({
        code_block: "~~~\nfoo\n~~~"
      })

      expect(parser.parse("~~~code_type\nfoo\n~~~")).to contain_parsed_output({
        code_block: "~~~code_type\nfoo\n~~~"
      })

      expect(parser.parse("```\nfoo")).to contain_parsed_output({
        code_block: "```\nfoo"
      })

      expect(parser.parse("~~~\nfoo")).to contain_parsed_output({
        code_block: "~~~\nfoo"
      })

      expect(parser.parse("    foo")).to contain_parsed_output({
        code_block: "    foo"
      })

      expect(parser.parse("\n    foo")).to contain_parsed_output({
        code_block: "\n    foo"
      })

      expect(parser.parse(" \n    foo")).to contain_parsed_output({
        code_block: " \n    foo"
      })

      expect(parser.parse("    foo\n    bar")).to contain_parsed_output({
        code_block: "    foo\n    bar"
      })

      expect(parser.parse("    foo\nbar")).to contain_parsed_output({
        code_block: "    foo\n"
      })

      expect(parser.parse("foo\nbar\n\n    foo\nbar")).to contain_parsed_output({
        code_block: "\n    foo\n"
      })
    end

    it 'should not recognise things that are not code blocks' do
      expect(parser.parse("bar\n    foo")).to contain_parsed_output({
        text: ["bar", "    foo"]
      })
    end

    it 'should recognise inline code blocks' do
      expect(parser.parse("`foo`")).to contain_parsed_output({
        inline_code: '`foo`'
      })

      expect(parser.parse("`foo\nbar`")).to contain_parsed_output({
        inline_code: "`foo\nbar`"
      })

      expect(parser.parse("``foo`bar``")).to contain_parsed_output({
        inline_code: "``foo`bar``"
      })

      expect(parser.parse("`````foo``bar`````")).to contain_parsed_output({
        inline_code: "`````foo``bar`````"
      })

      expect(parser.parse("`````foo``bar```")).to contain_parsed_output({
        inline_code: "```foo``bar```"
      })
    end

    it 'shouldn\'t recognise links inside code blocks' do
      expect(parser.parse("```foo\nbar [link](/link)\n```")).to contain_parsed_output({
        code_block: "```foo\nbar [link](/link)\n```"
      })
    end

    it 'shouldn\'t recognise links inside inline code blocks' do
      expect(parser.parse("`[foo](bar)`")).to contain_parsed_output({
        inline_code: "`[foo](bar)`"
      })
    end
  end

  describe 'tiddlylinks' do
    it 'should support basic tiddly links' do
      expect(parser.parse('[[foo link]]')).to contain_parsed_output({
        tiddler_link: { link: 'foo link' }
      })
    end

    it 'should support basic tiddly links with titles' do
      expect(parser.parse('[[the title|foo link]]')).to contain_parsed_output({
        tiddler_link: { link: 'foo link', title: 'the title' }
      })
    end

    it 'should support basic space links' do
      expect(parser.parse('@space-name')).to contain_parsed_output({
        space_link: { link: 'space-name' }
      })
    end

    it 'should support complex space links' do
      expect(parser.parse('@[[space name]]')).to contain_parsed_output({
        space_link: { link: 'space name' }
      })

      expect(parser.parse('@[[title|space name]]')).to contain_parsed_output({
        space_link: { title: 'title', link: 'space name' }
      })
    end

    it 'should support basic space tiddler links' do
      expect(parser.parse('tiddler-name@space-name')).to contain_parsed_output({
        tiddler_space_link: {
          tiddler_link: { link: 'tiddler-name' },
          space_link: { link: 'space-name' }
        }
      })
    end

    it 'should support complex space tiddler links' do
      expect(parser.parse('[[tiddler name]]@space-name')).to contain_parsed_output({
        tiddler_space_link: {
          tiddler_link: { link: 'tiddler name' },
          space_link: { link: 'space-name' }
        }
      })

      expect(parser.parse('[[title|tiddler name]]@space-name')).to contain_parsed_output({
        tiddler_space_link: {
          tiddler_link: { title: 'title', link: 'tiddler name' },
          space_link: { link: 'space-name' }
        }
      })

      expect(parser.parse('tiddler-name@[[space name]]')).to contain_parsed_output({
        tiddler_space_link: {
          tiddler_link: { link: 'tiddler-name' },
          space_link: { link: 'space name' }
        }
      })

      expect(parser.parse('[[tiddler name]]@[[space name]]')).to contain_parsed_output({
        tiddler_space_link: {
          tiddler_link: { link: 'tiddler name' },
          space_link: { link: 'space name' }
        }
      })

      expect(parser.parse('[[title|tiddler name]]@[[space name]]')).to contain_parsed_output({
        tiddler_space_link: {
          tiddler_link: { title: 'title', link: 'tiddler name' },
          space_link: { link: 'space name' }
        }
      })
    end

    it 'should support basic user space links' do
      expect(parser.parse('@user-name:space-name')).to contain_parsed_output({
        space_link: { user: 'user-name', link: 'space-name' }
      })
    end

    it 'should support complex user space links' do
      expect(parser.parse('@[[user name:space name]]')).to contain_parsed_output({
        space_link: { user: 'user name', link: 'space name' }
      })

      expect(parser.parse('@[[title|user name:space name]]')).to contain_parsed_output({
        space_link: { title: 'title', user: 'user name', link: 'space name' }
      })
    end

    it 'should support basic user space tiddler links' do
      expect(parser.parse('tiddler-name@user-name:space-name')).to contain_parsed_output({
        tiddler_space_link: {
          tiddler_link: { link: 'tiddler-name' },
          space_link: { user: 'user-name', link: 'space-name' }
        }
      })
    end

    it 'should support complex user space tiddler links' do
      expect(parser.parse('[[tiddler name]]@user-name:space-name')).to contain_parsed_output({
        tiddler_space_link: {
          tiddler_link: { link: 'tiddler name' },
          space_link: { user: 'user-name', link: 'space-name' }
        }
      })

      expect(parser.parse('[[title|tiddler name]]@user-name:space-name')).to contain_parsed_output({
        tiddler_space_link: {
          tiddler_link: { title: 'title', link: 'tiddler name' },
          space_link: { user: 'user-name', link: 'space-name' }
        }
      })

      expect(parser.parse('[[title|tiddler name]]@[[user name:space name]]')).to contain_parsed_output({
        tiddler_space_link: {
          tiddler_link: { title: 'title', link: 'tiddler name' },
          space_link: { user: 'user name', link: 'space name' }
        }
      })

      expect(parser.parse('[[tiddler name]]@[[user name:space name]]')).to contain_parsed_output({
        tiddler_space_link: {
          tiddler_link: { link: 'tiddler name' },
          space_link: { user: 'user name', link: 'space name' }
        }
      })

      expect(parser.parse('tiddler-name@[[user name:space name]]')).to contain_parsed_output({
        tiddler_space_link: {
          tiddler_link: { link: 'tiddler-name' },
          space_link: { user: 'user name', link: 'space name' }
        }
      })
    end
  end

  describe 'transclusions' do
    it 'should handle simple transclusions' do
      expect(parser.parse('{{{tiddler title}}}')).to contain_parsed_output({
        transclusion: { link: 'tiddler title' }
      })

      expect(parser.parse("foo\n{{{tiddler title}}}\nbar")).to contain_parsed_output({
        transclusion: { link: 'tiddler title' }
      })

      expect(parser.parse("\n{{{tiddler title}}}")).to contain_parsed_output({
        transclusion: { link: 'tiddler title' }
      })
    end

    it 'should not recognise transclusions that are not at the block level' do
      expect(parser.parse("foo {{{tiddler title}}}")).to contain_parsed_output({
        text: "foo {{{tiddler title}}}"
      })
    end

    it 'should handle transclusions using tiddly links' do
      expect(parser.parse('{{{[[tiddler title]]}}}')).to contain_parsed_output({
        transclusion: { tiddler_link: { link: 'tiddler title' } }
      })

      expect(parser.transclusion.parse('{{{tiddler-title@space}}}')).to contain_parsed_output({
        transclusion: {
          tiddler_space_link: {
            tiddler_link: { link: 'tiddler-title' },
            space_link: { link: 'space' }
          }
        }
      })

      expect(parser.transclusion.parse('{{{tiddler-title@user:space}}}')).to contain_parsed_output({
        transclusion: {
          tiddler_space_link: {
            tiddler_link: { link: 'tiddler-title' },
            space_link: { user: 'user', link: 'space' }
          }
        }
      })

      expect(parser.parse('{{{[[tiddler title]]@[[user name:space name]]}}}')).to contain_parsed_output({
        transclusion: {
          tiddler_space_link: {
            tiddler_link: { link: 'tiddler title' },
            space_link: { user: 'user name', link: 'space name' }
          }
        }
      })
    end
  end

end

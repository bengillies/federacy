require 'spec_helper'
require 'markdown/parser'

describe Markdown::Parser do

  let(:parser) { Markdown::Parser.new }

  describe 'standard markdown links' do
    it 'should parse standard markdown links' do
      expect(parser.parse("Foo bar [title here](/link/here)")).to contain_parsed_output({
        standard_link: { open: '[', title: 'title here', link: '/link/here', close: ')' }
      })

      expect(parser.parse("[title here](/link/here)")).to contain_parsed_output({
        standard_link: { open: '[', title: 'title here', link: '/link/here', close: ')' }
      })

      expect(parser.parse("[title here](/link/here) Foo bar")).to contain_parsed_output({
        standard_link: { open: '[', title: 'title here', link: '/link/here', close: ')' }
      })
    end

    it 'should support title attributes' do
      expect(parser.parse("[title here](/link/here \"alt\")")).to contain_parsed_output({
        standard_link: { open: '[', title: 'title here', link: '/link/here', title_attr: 'alt', close: ')' }
      })

      expect(parser.parse("[title here](/link/here 'alt')")).to contain_parsed_output({
        standard_link: { open: '[', title: 'title here', link: '/link/here', title_attr: 'alt', close: ')' }
      })
    end

    it 'should support image links' do
      expect(parser.parse("[![img](/img/link)](/link/here 'alt')")).to contain_parsed_output({
        standard_link: {
          image_link: { image_open: '!', open: '[', title: 'img', link: '/img/link', close: ')' },
          open: '[',
          link: '/link/here',
          title_attr: 'alt',
          close: ')'
        }
      })

      expect(
        parser.parse("[![img][ref]](/link/here 'alt')\n[ref]: /img/link")
      ).to contain_parsed_output({
        standard_link: {
          footer_image: { open: '[',image_open: '!',  title: 'img', reference: 'ref', close: ']' },
          link: '/link/here',
          title_attr: 'alt',
          open: '[',
          close: ')'
        },
        footer_reference: { reference: 'ref', link: '/img/link' }
      })

      expect(
        parser.parse("[![imgref][]](/link/here 'alt')\n[imgref]: /img/link")
      ).to contain_parsed_output({
        standard_link: {
          footer_image: { open: '[', image_open: '!', title_and_reference: 'imgref', close: '][]' },
          link: '/link/here',
          title_attr: 'alt',
          open: '[',
          close: ')'
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
        footer_link: { open: '[', title: 'title here', reference: 'ref', close: ']' },
        footer_reference: { link: '/link/here', reference: 'ref' }
      })

      expect(
        parser.parse("[title here]   [ref] Foo bar \n\n[ref]: /link/here")
      ).to contain_parsed_output({
        footer_link: { open: '[', title: 'title here', reference: 'ref', close: ']' },
        footer_reference: { link: '/link/here', reference: 'ref' }
      })

      expect(
        parser.parse("[ref] Foo bar \n\n[ref]: /link/here")
      ).to contain_parsed_output({
        footer_link: { open: '[', title_and_reference: 'ref', close: ']' },
        footer_reference: { link: '/link/here', reference: 'ref' }
      })

      expect(
        parser.parse("[ref] Foo bar \n\n[ref]: </link/here>")
      ).to contain_parsed_output({
        footer_link: { open: '[', title_and_reference: 'ref', close: ']' },
        footer_reference: { link: '/link/here', reference: 'ref' }
      })

      expect(
        parser.parse("[ref][] Foo bar \n\n[ref]: /link/here")
      ).to contain_parsed_output({
        footer_link: { open: '[', title_and_reference: 'ref', close: '][]' },
        footer_reference: { link: '/link/here', reference: 'ref' }
      })
    end

    it 'should support title attributes' do
      expect(
        parser.parse("[ref] Foo bar \n\n[ref]: /link/here \"alt\"")
      ).to contain_parsed_output({
        footer_link: { open: '[', title_and_reference: 'ref', close: ']' },
        footer_reference: { link: '/link/here', reference: 'ref', title_attr: 'alt' }
      })

      expect(
        parser.parse("[ref] Foo bar \n\n[ref]: /link/here 'alt'")
      ).to contain_parsed_output({
        footer_link: { open: '[', title_and_reference: 'ref', close: ']' },
        footer_reference: { link: '/link/here', reference: 'ref', title_attr: 'alt' }
      })

      expect(
        parser.parse("[ref] Foo bar \n\n[ref]: /link/here (alt)")
      ).to contain_parsed_output({
        footer_link: { open: '[', title_and_reference: 'ref', close: ']' },
        footer_reference: { link: '/link/here', reference: 'ref', title_attr: 'alt' }
      })

      expect(
        parser.parse("[ref] Foo bar \n\n[ref]: /link/here\n   \"alt\"")
      ).to contain_parsed_output({
        footer_link: { open: '[', title_and_reference: 'ref', close: ']' },
        footer_reference: { link: '/link/here', reference: 'ref', title_attr: 'alt' }
      })

      expect(
        parser.parse("[ref] Foo bar \n\n[ref]: </link/here>   \"alt\"")
      ).to contain_parsed_output({
        footer_link: { open: '[', title_and_reference: 'ref', close: ']' },
        footer_reference: { link: '/link/here', reference: 'ref', title_attr: 'alt' }
      })
    end

    it 'should support image links' do
      expect(
        parser.parse("[![img]][ref] Foo bar \n\n[ref]: </link/here>   \"alt\"\n[img]: /img/link")
      ).to contain_parsed_output({
        footer_link: { open: '[', footer_image: { open: '[', image_open: '!', title_and_reference: 'img', close: ']' }, reference: 'ref', close: ']' },
        footer_reference: [
          { link: '/link/here', reference: 'ref', title_attr: 'alt' },
          { link: '/img/link', reference: 'img' }
        ]
      })

      expect(
        parser.parse("[![img](/img/link)][ref] Foo bar \n\n[ref]: </link/here>   \"alt\"")
      ).to contain_parsed_output({
        footer_link: { open: '[', image_link: { open: '[', image_open: '!', title: 'img', link: '/img/link', close: ')' }, reference: 'ref', close: ']' },
        footer_reference: { link: '/link/here', reference: 'ref', title_attr: 'alt' }
      })
    end
  end

  describe 'images' do
    it 'should support regular images' do
      expect(parser.parse("![img](/img/link)")).to contain_parsed_output({
        image_link: { open: '[', image_open: '!', title: 'img', link: '/img/link', close: ')' }
      })
    end

    it 'should support images with title attributes' do
      expect(parser.parse("![img](/img/link \"alt\")")).to contain_parsed_output({
        image_link: { open: '[', image_open: '!', title: 'img', link: '/img/link', title_attr: 'alt', close: ')' }
      })

      expect(parser.parse("![img](/img/link 'alt')")).to contain_parsed_output({
        image_link: { open: '[', image_open: '!', title: 'img', link: '/img/link', title_attr: 'alt', close: ')' }
      })
    end

    it 'should support images by reference' do
      expect(parser.parse("![img][ref]\n[ref]: /img/link 'alt'")).to contain_parsed_output({
        footer_image: { open: '[', image_open: '!', title: 'img', reference: 'ref', close: ']' },
        footer_reference: { link: '/img/link', title_attr: 'alt', reference: 'ref' }
      })
    end
  end

  describe 'inline links' do
    it 'should parse links in angle brackets' do
      expect(parser.parse('<http://example.com/foo/bar/baz>')).to contain_parsed_output({
        inline_link: { open: '<', close: '>', link: 'http://example.com/foo/bar/baz' }
      })
    end

    it 'should parse auto links' do
      expect(parser.parse('http://example.com/foo/bar/baz')).to contain_parsed_output({
        inline_link: { link: 'http://example.com/foo/bar/baz' }
      })

      expect(parser.parse('https://example.com/foo/bar/baz')).to contain_parsed_output({
        inline_link: { link: 'https://example.com/foo/bar/baz' }
      })

      expect(parser.parse('ftp://example.com/foo/bar/baz')).to contain_parsed_output({
        inline_link: { link: 'ftp://example.com/foo/bar/baz' }
      })

      expect(parser.parse('www.example.com:3000/foo/bar/baz')).to contain_parsed_output({
        inline_link: { link: 'www.example.com:3000/foo/bar/baz' }
      })
    end

    it 'should handle multiple links' do
      expect(parser.parse('www.example.com http://foo.com')).to contain_parsed_output({
        inline_link: [{ link: 'www.example.com' }, { link: ' http://foo.com' }]
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
        tiddler_link: { open: '[[', link: 'foo link', close: ']]' }
      })
    end

    it 'should support basic tiddly links with titles' do
      expect(parser.parse('[[the title|foo link]]')).to contain_parsed_output({
        tiddler_link: { open: '[[', link: 'foo link', title: 'the title', close: ']]' }
      })
    end

    it 'should support multiple links' do
      expect(parser.parse('[[the]] [[title|foo link]]')).to contain_parsed_output({
        tiddler_link: [
          { open: '[[', link: 'the', close: ']]' },
          { open: '[[', link: 'foo link', title: 'title', close: ']]' }
        ]
      })
    end

    it 'should support basic space links' do
      expect(parser.parse('@space-name')).to contain_parsed_output({
        space_link: { at: '@', link: 'space-name' }
      })
    end

    it 'should support complex space links' do
      expect(parser.parse('@[[space name]]')).to contain_parsed_output({
        space_link: { at: '@', open: '[[',  link: 'space name', close: ']]' }
      })

      expect(parser.parse('@[[title|space name]]')).to contain_parsed_output({
        space_link: { open: '[[', at: '@',  title: 'title', link: 'space name', close: ']]' }
      })
    end

    it 'should support multiple complex space links' do
      expect(parser.parse('@[[foo|bar]] @user:space  @[[title|user:name]]')).to contain_parsed_output({
        space_link: [
         { at: '@', open: '[[', close: ']]', title: 'foo', link: 'bar' },
         { at: '@', user: 'user', link: 'space' },
         { at: '@', open: '[[', user: 'user', title: 'title', link: 'name', close: ']]' }
        ]
      })

      expect(parser.parse('@[[title|space name]]')).to contain_parsed_output({
        space_link: { open: '[[', at: '@',  title: 'title', link: 'space name', close: ']]' }
      })
    end

    it 'should support basic space tiddler links' do
      expect(parser.parse('tiddler-name@space-name')).to contain_parsed_output({
        tiddler_space_link: {
          tiddler_link: { link: 'tiddler-name' },
          space_link: { at: '@', link: 'space-name' }
        }
      })
    end

    it 'should support complex space tiddler links' do
      expect(parser.parse('[[tiddler name]]@space-name')).to contain_parsed_output({
        tiddler_space_link: {
          tiddler_link: { open: '[[', link: 'tiddler name', close: ']]' },
          space_link: { at: '@', link: 'space-name' }
        }
      })

      expect(parser.parse('[[title|tiddler name]]@space-name')).to contain_parsed_output({
        tiddler_space_link: {
          tiddler_link: { open: '[[', title: 'title', link: 'tiddler name', close: ']]' },
          space_link: { at: '@', link: 'space-name' }
        }
      })

      expect(parser.parse('tiddler-name@[[space name]]')).to contain_parsed_output({
        tiddler_space_link: {
          tiddler_link: { link: 'tiddler-name' },
          space_link: { at: '@', open: '[[',  link: 'space name', close: ']]' }
        }
      })

      expect(parser.parse('[[tiddler name]]@[[space name]]')).to contain_parsed_output({
        tiddler_space_link: {
          tiddler_link: { open: '[[', link: 'tiddler name', close: ']]' },
          space_link: { open: '[[', at: '@',  link: 'space name', close: ']]' }
        }
      })

      expect(parser.parse('[[title|tiddler name]]@[[space name]]')).to contain_parsed_output({
        tiddler_space_link: {
          tiddler_link: { open: '[[', title: 'title', link: 'tiddler name', close: ']]' },
          space_link: { open: '[[', at: '@',  link: 'space name', close: ']]' }
        }
      })
    end

    it 'should support basic user space links' do
      expect(parser.parse('@user-name:space-name')).to contain_parsed_output({
        space_link: { at: '@', user: 'user-name', link: 'space-name' }
      })
    end

    it 'should support complex user space links' do
      expect(parser.parse('@[[user name:space name]]')).to contain_parsed_output({
        space_link: { at: '@', open: '[[',  user: 'user name', link: 'space name', close: ']]' }
      })

      expect(parser.parse('@[[title|user name:space name]]')).to contain_parsed_output({
        space_link: { at: '@', open: '[[',  title: 'title', user: 'user name', link: 'space name', close: ']]' }
      })
    end

    it 'should support basic user space tiddler links' do
      expect(parser.parse('tiddler-name@user-name:space-name')).to contain_parsed_output({
        tiddler_space_link: {
          tiddler_link: { link: 'tiddler-name' },
          space_link: { at: '@', user: 'user-name', link: 'space-name' }
        }
      })
    end

    it 'should support complex user space tiddler links' do
      expect(parser.parse('[[tiddler name]]@user-name:space-name')).to contain_parsed_output({
        tiddler_space_link: {
          tiddler_link: { open: '[[', link: 'tiddler name', close: ']]' },
          space_link: { at: '@', user: 'user-name', link: 'space-name' }
        }
      })

      expect(parser.parse('[[title|tiddler name]]@user-name:space-name')).to contain_parsed_output({
        tiddler_space_link: {
          tiddler_link: { open: '[[', title: 'title', link: 'tiddler name', close: ']]' },
          space_link: { at: '@', user: 'user-name', link: 'space-name' }
        }
      })

      expect(parser.parse('[[title|tiddler name]]@[[user name:space name]]')).to contain_parsed_output({
        tiddler_space_link: {
          tiddler_link: { open: '[[', title: 'title', link: 'tiddler name', close: ']]' },
          space_link: { open: '[[', at: '@',  user: 'user name', link: 'space name', close: ']]' }
        }
      })

      expect(parser.parse('[[tiddler name]]@[[user name:space name]]')).to contain_parsed_output({
        tiddler_space_link: {
          tiddler_link: { open: '[[', link: 'tiddler name', close: ']]' },
          space_link: { open: '[[', at: '@',  user: 'user name', link: 'space name', close: ']]' }
        }
      })

      expect(parser.parse('tiddler-name@[[user name:space name]]')).to contain_parsed_output({
        tiddler_space_link: {
          tiddler_link: { link: 'tiddler-name' },
          space_link: { at: '@', open: '[[',  user: 'user name', link: 'space name', close: ']]' }
        }
      })
    end
  end

  describe 'tiddlyimages' do
    it 'should support tiddlyimages' do
      expect(parser.parse('![[foo]]')).to contain_parsed_output({
        tiddler_image: { image_open: '!', tiddler_link: { open: '[[', link: 'foo', close: ']]' } }
      })

      expect(parser.parse('![[foo|bar]]')).to contain_parsed_output({
        tiddler_image: {
          image_open: '!',
          tiddler_link: { open: '[[', title: 'foo', link: 'bar', close: ']]' }
        }
      })

      expect(parser.parse('!foo@bar')).to contain_parsed_output({
        tiddler_image: {
          image_open: '!',
          tiddler_space_link: {
            tiddler_link: { link: 'foo' },
            space_link: { link: 'bar', at: '@' }
          }
        }
      })
    end

    it 'should support embedding tiddlyimages inside tiddlylinks' do
      expect(parser.parse('[[![[foo]]|bar]]')).to contain_parsed_output({
        tiddler_link: {
          open: '[[',
          link: 'bar',
          close: ']]',
          tiddler_image: {
            image_open: '!',
            tiddler_link: { open: '[[', link: 'foo', close: ']]' }
          }
        }
      })

      expect(parser.parse('[[![[foo|bar]]|baz]]')).to contain_parsed_output({
        tiddler_link: {
          open: '[[',
          link: 'baz',
          close: ']]',
          tiddler_image: {
            image_open: '!',
            tiddler_link: { open: '[[', title: 'foo', link: 'bar', close: ']]' }
          }
        }
      })

      expect(parser.parse('[[!foo@bar|baz]]')).to contain_parsed_output({
        tiddler_link: {
          open: '[[',
          link: 'baz',
          close: ']]',
          tiddler_image: {
            image_open: '!',
            tiddler_space_link: {
              tiddler_link: { link: 'foo' },
              space_link: { link: 'bar', at: '@' }
            }
          }
        }
      })
    end
  end

  describe 'transclusions' do
    it 'should handle simple transclusions' do
      expect(parser.parse('{{tiddler title}}')).to contain_parsed_output({
        transclusion: { open: '{{', link: 'tiddler title', close: '}}' }
      })

      expect(parser.parse("foo\n{{tiddler title}}\nbar")).to contain_parsed_output({
        transclusion: { open: '{{', link: 'tiddler title', close: '}}' }
      })

      expect(parser.parse("\n{{tiddler title}}")).to contain_parsed_output({
        transclusion: { open: '{{', link: 'tiddler title', close: '}}' }
      })
    end

    it 'should not recognise transclusions that are not at the block level' do
      expect(parser.parse("foo {{tiddler title}}")).to contain_parsed_output({
        text: "foo {{tiddler title}}"
      })
    end

    it 'should handle transclusions using tiddly links' do
      expect(parser.parse('{{[[tiddler title]]}}')).to contain_parsed_output({
        transclusion: { open: '{{', tiddler_link: { open: '[[', link: 'tiddler title' , close: ']]'}, close: '}}' }
      })

      expect(parser.transclusion.parse('{{tiddler-title@space}}')).to contain_parsed_output({
        transclusion: {
          open: '{{',
          tiddler_space_link: {
            tiddler_link: { link: 'tiddler-title' },
            space_link: { at: '@', link: 'space' }
          },
         close: '}}'
        }
      })

      expect(parser.transclusion.parse('{{tiddler-title@user:space}}')).to contain_parsed_output({
        transclusion: {
          open: '{{',
          tiddler_space_link: {
            tiddler_link: { link: 'tiddler-title' },
            space_link: { at: '@', user: 'user', link: 'space' }
          },
          close: '}}'
        }
      })

      expect(parser.parse('{{[[tiddler title]]@[[user name:space name]]}}')).to contain_parsed_output({
        transclusion: {
          open: '{{',
          tiddler_space_link: {
            tiddler_link: { open: '[[', link: 'tiddler title', close: ']]' },
            space_link: { open: '[[', at: '@',  user: 'user name', link: 'space name', close: ']]' }
          },
          close: '}}'
        }
      })
    end

    it 'should handle transclusions using tiddly images' do
      expect(parser.parse('{{![[tiddler title]]}}')).to contain_parsed_output({
        transclusion: {
          open: '{{',
          tiddler_image: {
            image_open: '!',
            tiddler_link: {
              open: '[[',
              link: 'tiddler title',
              close: ']]'
            }
          },
          close: '}}'
        }
      })

      expect(parser.transclusion.parse('{{!tiddler-title@space}}')).to contain_parsed_output({
        transclusion: {
          open: '{{',
          tiddler_image: {
            image_open: '!',
            tiddler_space_link: {
              tiddler_link: { link: 'tiddler-title' },
              space_link: { at: '@', link: 'space' }
            }
          },
          close: '}}'
        }
      })

      expect(parser.transclusion.parse('{{!tiddler-title@user:space}}')).to contain_parsed_output({
        transclusion: {
          open: '{{',
          tiddler_image: {
            image_open: '!',
            tiddler_space_link: {
              tiddler_link: { link: 'tiddler-title' },
              space_link: { at: '@', user: 'user', link: 'space' }
            }
          },
          close: '}}'
        }
      })

      expect(parser.parse('{{![[tiddler title]]@[[user name:space name]]}}')).to contain_parsed_output({
        transclusion: {
          open: '{{',
          tiddler_image: {
            image_open: '!',
            tiddler_space_link: {
              tiddler_link: { open: '[[', link: 'tiddler title', close: ']]' },
              space_link: {
                open: '[[',
                at: '@',
                user: 'user name',
                link: 'space name',
                close: ']]'
              }
            }
          },
          close: '}}'
        }
      })
    end
  end

end

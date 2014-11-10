require 'spec_helper'
require 'federacy_markdown_parser'

describe FederacyMarkdownParser do

  def pluck_tree key_names, obj
    key_names = [key_names] unless key_names.respond_to? :each
    res = {}
    Class.new(Parslet::Transform) do
      key_names.each do |key_name|
        rule(key_name => subtree(:x)) do |dictionary|
          if res[key_name].respond_to? :push
            res[key_name] << dictionary[:x]
          elsif res[key_name].present?
            res[key_name] = [res[key_name], dictionary[:x]]
          else
            res[key_name] = dictionary[:x]
          end
        end
      end
    end.new.apply(obj)
    res
  end

  let(:parser) { FederacyMarkdownParser.new }

  describe 'standard markdown links' do
    it 'should parse standard markdown links' do
      expect(pluck_tree(
        :standard_link, parser.parse("Foo bar [title here](/link/here)")
      )).to include({
        standard_link: { title: 'title here', link: '/link/here' }
      })

      expect(pluck_tree(
        :standard_link, parser.parse("[title here](/link/here)")
      )).to include({
        standard_link: { title: 'title here', link: '/link/here' }
      })

      expect(pluck_tree(
        :standard_link, parser.parse("[title here](/link/here) Foo bar")
      )).to include({
        standard_link: { title: 'title here', link: '/link/here' }
      })
    end

    it 'should support title attributes' do
      expect(pluck_tree(
        :standard_link, parser.parse("[title here](/link/here \"alt\")")
      )).to include({
        standard_link: { title: 'title here', link: '/link/here', title_attr: 'alt' }
      })

      expect(pluck_tree(
        :standard_link, parser.parse("[title here](/link/here 'alt')")
      )).to include({
        standard_link: { title: 'title here', link: '/link/here', title_attr: 'alt' }
      })
    end

    it 'should support image links' do
      expect(pluck_tree(
        :standard_link, parser.parse("[![img](/img/link)](/link/here 'alt')")
      )).to include({
        standard_link: {
          image_link: { title: 'img', link: '/img/link' },
          link: '/link/here',
          title_attr: 'alt'
        }
      })

      expect(pluck_tree(
        [:standard_link, :footer_reference],
        parser.parse("[![img][ref]](/link/here 'alt')\n[ref]: /img/link")
      )).to include({
        standard_link: {
          footer_image: { title: 'img', reference: 'ref' },
          link: '/link/here',
          title_attr: 'alt'
        },
        footer_reference: { reference: 'ref', link: '/img/link' }
      })
    end
  end

  describe 'footer links' do
    it 'should parse standard links in footer reference format' do
      expect(pluck_tree(
        [:footer_link, :footer_reference],
        parser.parse("[title here][ref] Foo bar \n\n[ref]: /link/here")
      )).to eq({
        footer_link: { title: 'title here', reference: 'ref' },
        footer_reference: { link: '/link/here', reference: 'ref' }
      })

      expect(pluck_tree(
        [:footer_link, :footer_reference],
        parser.parse("[title here]   [ref] Foo bar \n\n[ref]: /link/here")
      )).to eq({
        footer_link: { title: 'title here', reference: 'ref' },
        footer_reference: { link: '/link/here', reference: 'ref' }
      })

      expect(pluck_tree(
        [:footer_link, :footer_reference],
        parser.parse("[ref] Foo bar \n\n[ref]: /link/here")
      )).to eq({
        footer_link: { title_and_reference: 'ref' },
        footer_reference: { link: '/link/here', reference: 'ref' }
      })

      expect(pluck_tree(
        [:footer_link, :footer_reference],
        parser.parse("[ref] Foo bar \n\n[ref]: </link/here>")
      )).to eq({
        footer_link: { title_and_reference: 'ref' },
        footer_reference: { link: '/link/here', reference: 'ref' }
      })

      expect(pluck_tree(
        [:footer_link, :footer_reference],
        parser.parse("[ref][] Foo bar \n\n[ref]: /link/here")
      )).to eq({
        footer_link: { title_and_reference: 'ref' },
        footer_reference: { link: '/link/here', reference: 'ref' }
      })
    end

    it 'should support title attributes' do
      expect(pluck_tree(
        [:footer_link, :footer_reference],
        parser.parse("[ref] Foo bar \n\n[ref]: /link/here \"alt\"")
      )).to eq({
        footer_link: { title_and_reference: 'ref' },
        footer_reference: { link: '/link/here', reference: 'ref', title_attr: 'alt' }
      })

      expect(pluck_tree(
        [:footer_link, :footer_reference],
        parser.parse("[ref] Foo bar \n\n[ref]: /link/here 'alt'")
      )).to eq({
        footer_link: { title_and_reference: 'ref' },
        footer_reference: { link: '/link/here', reference: 'ref', title_attr: 'alt' }
      })

      expect(pluck_tree(
        [:footer_link, :footer_reference],
        parser.parse("[ref] Foo bar \n\n[ref]: /link/here (alt)")
      )).to eq({
        footer_link: { title_and_reference: 'ref' },
        footer_reference: { link: '/link/here', reference: 'ref', title_attr: 'alt' }
      })

      expect(pluck_tree(
        [:footer_link, :footer_reference],
        parser.parse("[ref] Foo bar \n\n[ref]: /link/here\n   \"alt\"")
      )).to eq({
        footer_link: { title_and_reference: 'ref' },
        footer_reference: { link: '/link/here', reference: 'ref', title_attr: 'alt' }
      })

      expect(pluck_tree(
        [:footer_link, :footer_reference],
        parser.parse("[ref] Foo bar \n\n[ref]: </link/here>   \"alt\"")
      )).to eq({
        footer_link: { title_and_reference: 'ref' },
        footer_reference: { link: '/link/here', reference: 'ref', title_attr: 'alt' }
      })
    end

    it 'should support image links' do
      expect(pluck_tree(
        [:footer_link, :footer_reference],
        parser.parse("[![img]][ref] Foo bar \n\n[ref]: </link/here>   \"alt\"\n[img]: /img/link")
      )).to eq({
        footer_link: { footer_image: { title_and_reference: 'img' }, reference: 'ref' },
        footer_reference: [
          { link: '/link/here', reference: 'ref', title_attr: 'alt' },
          { link: '/img/link', reference: 'img' }
        ]
      })

      expect(pluck_tree(
        [:footer_link, :footer_reference],
        parser.parse("[![img](/img/link)][ref] Foo bar \n\n[ref]: </link/here>   \"alt\"")
      )).to eq({
        footer_link: { image_link: { title: 'img', link: '/img/link' }, reference: 'ref' },
        footer_reference: { link: '/link/here', reference: 'ref', title_attr: 'alt' }
      })
    end
  end

  describe 'images' do
    it 'should support regular images' do
      expect(pluck_tree(
        :image_link,
        parser.parse("![img](/img/link)")
      )).to eq({
        image_link: { title: 'img', link: '/img/link' }
      })
    end

    it 'should support images with title attributes' do
      expect(pluck_tree(
        :image_link,
        parser.parse("![img](/img/link \"alt\")")
      )).to eq({
        image_link: { title: 'img', link: '/img/link', title_attr: 'alt' }
      })

      expect(pluck_tree(
        :image_link,
        parser.parse("![img](/img/link 'alt')")
      )).to eq({
        image_link: { title: 'img', link: '/img/link', title_attr: 'alt' }
      })
    end

    it 'should support images by reference' do
      expect(pluck_tree(
        [:footer_image, :footer_reference],
        parser.parse("![img][ref]\n[ref]: /img/link 'alt'")
      )).to eq({
        footer_image: { title: 'img', reference: 'ref' },
        footer_reference: { link: '/img/link', title_attr: 'alt', reference: 'ref' }
      })
    end
  end

end

require 'rails_helper'

RSpec.describe EventsHelper, type: :helper do
  describe '#text_with_links' do
    it 'http と https の URL を新しいタブで開くリンクにする' do
      html = Nokogiri::HTML.fragment(helper.text_with_links('地図 https://example.com/map?a=1&b=2 と http://example.org'))
      links = html.css('a')

      expect(links.map { |a| a['href'] }).to eq [ 'https://example.com/map?a=1&b=2', 'http://example.org' ]
      expect(links.map(&:text)).to eq [ 'https://example.com/map?a=1&b=2', 'http://example.org' ]
      expect(links.map { |a| a['target'] }).to all(eq '_blank')
      expect(links.map { |a| a['rel'] }).to all(eq 'noopener noreferrer nofollow ugc')
      expect(html.text).to eq '地図 https://example.com/map?a=1&b=2 と http://example.org'
    end

    it 'URL の後ろの句読点と閉じ括弧はリンクに含めない' do
      html = Nokogiri::HTML.fragment(helper.text_with_links('会場（https://example.com/a）。https://example.com/b.'))

      expect(html.css('a').map { |a| a['href'] }).to eq [ 'https://example.com/a', 'https://example.com/b' ]
    end

    it 'ほかのスキームとタグは文字のまま出す' do
      html = Nokogiri::HTML.fragment(helper.text_with_links('javascript:alert(1) <b>太字</b> ftp://example.com'))

      expect(html.css('a, b')).to be_empty
      expect(html.text).to eq 'javascript:alert(1) <b>太字</b> ftp://example.com'
    end

    it 'URL の中の引用符でリンクの属性を抜け出さない' do
      html = Nokogiri::HTML.fragment(helper.text_with_links('https://example.com/"onclick="x'))

      expect(html.css('a').map { |a| a.attributes.keys.sort }).to eq [ %w[class href rel target] ]
    end
  end

  describe '#format_with_links' do
    it '改行を段落と改行にし、URL をリンクにする' do
      html = Nokogiri::HTML.fragment(helper.format_with_links("1行目\nhttps://example.com\n\n<p>次</p>"))

      expect(html.css('p').size).to eq 2
      expect(html.css('br').size).to eq 1
      expect(html.css('a').map { |a| a['href'] }).to eq [ 'https://example.com' ]
      expect(html.css('p').last.text).to eq '<p>次</p>'
    end
  end
end

require "rails_helper"

RSpec.describe "エラーページ" do
  %w[400 404 406-unsupported-browser 422 500].each do |name|
    describe "#{name}.html" do
      let(:html) { Nokogiri::HTML(Rails.public_path.join("#{name}.html").read) }

      it "日本語の文書で、英語の文言が残っていない" do
        expect(html.at("html")["lang"]).to eq "ja"
        expect(html.at("title").text).to match(/\p{Han}|\p{Hiragana}|\p{Katakana}/)
        expect(html.at("body").text).not_to match(/[A-Za-z]{4,}/)
      end

      it "イベント一覧へ戻るリンクがある" do
        link = html.at('a[href="/"]')
        expect(link.text.strip).to eq "イベント一覧へ"
      end
    end
  end
end

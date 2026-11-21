require "rails_helper"

RSpec.describe "共有用のメタ情報", type: :request do
  def og(property)
    Nokogiri::HTML(response.body).at(%(meta[property="og:#{property}"]))&.[]("content")
  end

  let(:event) do
    create(:event,
           name: "三鷹 Ruby <会>",
           location: "三鷹駅前 & 2F",
           start_at: Time.zone.local(2030, 1, 15, 19, 0),
           end_at: Time.zone.local(2030, 1, 15, 21, 0),
           participant_notice: "合言葉は秘密")
  end

  it "イベント詳細にイベント名・日時と場所・URL を出す" do
    get event_path(event)

    expect(og("title")).to eq "三鷹 Ruby <会>"
    expect(og("description")).to eq "2030年1月15日(火) 19:00〜21:00 三鷹駅前 & 2F"
    expect(og("url")).to eq event_url(event)
    expect(og("type")).to eq "website"
    expect(og("site_name")).to eq "Beerkeeper"
    expect(response.body).to include("三鷹 Ruby &lt;会&gt;")
    expect(response.body).not_to include("三鷹 Ruby <会>")
    expect(response.body).not_to include("合言葉は秘密")
  end

  it "場所が無ければ日時だけを出す" do
    event.update!(location: "")
    get event_path(event)

    expect(og("description")).to eq "2030年1月15日(火) 19:00〜21:00"
  end

  it "中止したイベントは先頭に中止と出す" do
    event.cancel
    get event_path(event)

    expect(og("description")).to eq "中止 2030年1月15日(火) 19:00〜21:00 三鷹駅前 & 2F"
  end

  it "ほかの画面はサイト名だけを出す" do
    get root_path

    expect(og("title")).to eq "Beerkeeper"
    expect(og("site_name")).to eq "Beerkeeper"
    expect(og("description")).to be_nil
    expect(og("url")).to be_nil
  end
end

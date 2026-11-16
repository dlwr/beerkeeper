require "rails_helper"

RSpec.describe "イベント詳細の操作", type: :request do
  let(:organizer) { create(:user) }
  let(:user) { create(:user) }
  let(:event) do
    create(:event, organizer:, max_size: 1, location: "三鷹",
                   start_at: Time.zone.local(2099, 1, 15, 19, 30), end_at: Time.zone.local(2099, 1, 15, 21, 0))
  end

  def page_html
    Nokogiri::HTML(response.body)
  end

  def primary_buttons
    page_html.css("main .btn-primary")
  end

  it "日時・場所・残りの枠を説明より先に出す" do
    event.update!(description: "説明の本文")

    get event_path(event)

    expect(event_fact("日時")).to eq "2099年1月15日(木) 19:30〜21:00"
    expect(event_fact("場所")).to eq "三鷹"
    expect(event_fact("参加人数")).to eq "0人 / 1人 あと1人"
    expect(response.body.index("event-facts")).to be < response.body.index("説明の本文")
  end

  it "未ログインには Discord でログインして参加するを主な操作として出す" do
    get event_path(event)

    expect(primary_buttons.map { |b| b.text.strip }).to eq [ "Discord でログインして参加する" ]
    expect(primary_buttons.first["href"]).to eq login_path(return_to: event_path(event))
  end

  it "参加できる人には参加するだけを主な操作として出す" do
    log_in(user)

    get event_path(event)

    expect(primary_buttons.map { |b| b.text.strip }).to eq [ "参加する" ]
  end

  it "満席なら補欠になることを添える" do
    create(:participation, event:, user: create(:user))
    log_in(user)

    get event_path(event)

    expect(primary_buttons.map { |b| b.text.strip }).to eq [ "参加する" ]
    expect(page_html.at(".event-action").text).to include "満席のため補欠で申し込みます"
  end

  it "参加者には参加予定であることとキャンセルだけを出す" do
    create(:participation, event:, user:)
    log_in(user)

    get event_path(event)

    action = page_html.at(".event-action")
    expect(action.text).to include "参加予定です"
    expect(action.css("button").map { |b| b.text.strip }).to eq [ "参加をキャンセルする" ]
    expect(primary_buttons).to be_empty
  end

  it "補欠には順番とキャンセルだけを出す" do
    create(:participation, event:, user: create(:user))
    create(:participation, event:, user:, waitlisted: true)
    log_in(user)

    get event_path(event)

    action = page_html.at(".event-action")
    expect(action.text).to include "補欠の1番目です"
    expect(action.css("button").map { |b| b.text.strip }).to eq [ "参加をキャンセルする" ]
  end

  it "終了と中止では参加の操作を出さない" do
    ended = create(:event, start_at: 2.days.ago, end_at: 1.day.ago)
    get event_path(ended)
    expect(primary_buttons).to be_empty

    event.cancel
    get event_path(event)
    expect(primary_buttons).to be_empty
  end

  it "主催者向けの操作を見出しでまとめ、中止は危険な操作として分ける" do
    log_in(organizer)

    get event_path(event)

    section = page_html.at("section.organizer-actions")
    expect(section.at("h2").text.strip).to eq "主催者向けの操作"
    expect(section.css("a").map { |a| a.text.strip }).to eq [ "編集", "このイベントをもとに作成" ]
    expect(section.at("button.btn-outline-danger, input.btn-outline-danger")).to be_present
    expect(section.at("label[for='cancellation_reason']")).to be_present
    expect(primary_buttons.map { |b| b.text.strip }).to eq [ "参加する" ]
  end

  it "参加者リストを見出しにする" do
    create(:participation, event:, user:)

    get event_path(event)

    expect(page_html.css("main h2").map { |h| h.text.strip }).to include "参加者リスト"
  end
end

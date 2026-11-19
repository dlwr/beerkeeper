require 'rails_helper'

RSpec.describe "過去のイベント", type: :request do
  before do
    Participation.delete_all
    Event::Cancellation.delete_all
    Event.delete_all
  end

  def create_past_events(count)
    Array.new(count) do |i|
      day = Time.zone.local(2020, 1, 1) + i.days
      create(:event, name: "過去の会#{i + 1}", start_at: day + 19.hours, end_at: day + 21.hours)
    end
  end

  def past_section
    Nokogiri::HTML(response.body).at('section[aria-labelledby="past-heading"]')
  end

  def event_names(node)
    node.css('.event-item__name').map { |h| h.text.strip }
  end

  describe 'GET /events' do
    it '過去のイベントは新しい 5 件だけを出し、すべて見るリンクを出す' do
      create_past_events(6)

      get events_path

      expect(event_names(past_section)).to eq %w[過去の会6 過去の会5 過去の会4 過去の会3 過去の会2]
      expect(past_section.at(%(a[href="#{past_events_path}"])).text.strip).to eq '過去のイベントをすべて見る'
    end

    it '過去のイベントが 5 件以下ならすべて見るリンクを出さない' do
      create_past_events(5)

      get events_path

      expect(event_names(past_section).size).to eq 5
      expect(past_section.at(%(a[href="#{past_events_path}"]))).to be_nil
    end
  end

  describe 'GET /events/past' do
    it 'ログインしていなくても、新しい順に 20 件ずつ出し、古いイベントへのリンクを出す' do
      create_past_events(21)

      get past_events_path

      expect(response).to have_http_status(:ok)
      html = Nokogiri::HTML(response.body)
      expect(html.at('h1').text.strip).to eq '過去のイベント'
      names = event_names(html)
      expect(names.size).to eq 20
      expect(names.first).to eq '過去の会21'
      expect(names.last).to eq '過去の会2'
      expect(html.at(%(a[href="#{past_events_path(page: 2)}"])).text.strip).to eq '古いイベント'
      expect(html.css('a').map { |a| a.text.strip }).not_to include('新しいイベント')
    end

    it '2 ページ目は残りを出し、新しいイベントへのリンクを出す' do
      create_past_events(21)

      get past_events_path(page: 2)

      html = Nokogiri::HTML(response.body)
      expect(event_names(html)).to eq %w[過去の会1]
      expect(html.at(%(a[href="#{past_events_path}"])).text.strip).to eq '新しいイベント'
      expect(html.css('a').map { |a| a.text.strip }).not_to include('古いイベント')
    end

    it '開催予定と中止したイベントは出さない' do
      create_past_events(1)
      create(:event, name: '次の会')
      create_past_events(1).first.tap { |e| e.update!(name: '中止した会') }.cancel('雨')

      get past_events_path

      expect(event_names(Nokogiri::HTML(response.body))).to eq %w[過去の会1]
    end

    it '範囲外や数字でないページでもエラーにしない' do
      create_past_events(1)

      [ '0', '-1', 'x' ].each do |page|
        get past_events_path(page:)

        expect(event_names(Nokogiri::HTML(response.body))).to eq %w[過去の会1]
      end

      get past_events_path(page: '100000000000000000000')

      expect(response).to have_http_status(:ok)
    end
  end
end

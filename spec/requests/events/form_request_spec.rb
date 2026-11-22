require "rails_helper"

RSpec.describe "イベントのフォーム", type: :request do
  let(:user) { create(:user) }

  before { log_in(user) }

  def form_html
    Nokogiri::HTML(response.body).at("main form")
  end

  def valid_params(**overrides)
    { start_at_date: "2099-03-14", start_at_time: "18:30", end_at_date: "2099-03-14", end_at_time: "21:00",
      name: "定例会", location: "三鷹" }.merge(overrides)
  end

  it "すべての入力欄に label を結びつける" do
    get new_event_path

    fields = form_html.css("input:not([type=hidden]):not([type=submit]), textarea, select")
    expect(fields).not_to be_empty
    fields.each do |field|
      expect(form_html.at(%(label[for="#{field['id']}"]))).to be_present, "#{field['name']} に label が無い"
    end
  end

  it "欄をイベント名・日時・場所の順に並べる" do
    event = create(:event, organizer: user)
    expected = %w[event_name event_start_at_date event_start_at_time event_end_at_date event_end_at_time event_location
                  event_max_size event_budget event_description event_participant_notice]

    [ new_event_path, edit_event_path(event) ].each do |path|
      get path

      ids = form_html.css("input:not([type=hidden]):not([type=submit]), textarea").map { _1["id"] }
      expect(ids).to eq(expected), path
    end
  end

  it "必須と任意を文字で示す" do
    get new_event_path

    label_text = ->(id) { form_html.at(%(label[for="#{id}"])).text.squish }
    expect(label_text.call("event_name")).to include "必須"
    expect(form_html.at("fieldset.event-start legend").text).to include "必須"
    expect(label_text.call("event_end_at_date")).to include "任意"
    expect(label_text.call("event_end_at_time")).to include "必須"
    %w[event_location event_max_size event_budget event_description event_participant_notice].each do |id|
      expect(label_text.call(id)).to include "任意"
    end
  end

  it "参加人数は数字の入力にする" do
    get new_event_path

    field = form_html.at("#event_max_size")
    expect(field["inputmode"]).to eq "numeric"
    expect(field["min"]).to eq "1"
  end

  it "イベント名が空なら欄のすぐ下にエラーを出し、ほかの入力を残す" do
    post events_path, params: { event: valid_params(name: "") }

    expect(response).to have_http_status(:unprocessable_content)
    field = form_html.at("#event_name")
    expect(field["aria-invalid"]).to eq "true"
    error = form_html.at("##{field['aria-describedby']}")
    expect(error.text.squish).to eq "イベント名を入力してください"
    expect(field.parent.css(".field-error").map { |e| e["id"] }).to eq [ error["id"] ]
    expect(form_html.at("#event_location")["value"]).to eq "三鷹"
    expect(form_html.at("#event_start_at_time")["value"]).to eq "18:30"
  end

  it "開始日時が空なら開始の欄の近くにエラーを出す" do
    post events_path, params: { event: valid_params(start_at_date: "", start_at_time: "") }

    fieldset = form_html.at("fieldset.event-start")
    expect(fieldset.at(".field-error").text).to include "開始日時を入力してください"
    expect(fieldset.at("#event_start_at_date")["aria-invalid"]).to eq "true"
  end

  it "終了が開始より前なら終了の欄の近くにエラーを出す" do
    post events_path, params: { event: valid_params(end_at_time: "17:00") }

    fieldset = form_html.at("fieldset.event-end")
    expect(fieldset.at(".field-error").text).to include "終了日時は開始日時より後にしてください"
  end

  it "終了日は任意で、空なら開始と同じ日と補足する" do
    get new_event_path

    field = form_html.at("#event_end_at_date")
    expect(field["required"]).to be_nil
    hint = form_html.at("##{field['aria-describedby']}")
    expect(hint.text.squish).to eq "空なら開始と同じ日"
  end

  it "終了日が空なら開始と同じ日の終了時刻で保存する" do
    post events_path, params: { event: valid_params(end_at_date: "") }

    event = Event.find_by!(name: "定例会")
    expect(event.end_at).to eq Time.zone.local(2099, 3, 14, 21, 0)
  end

  it "終了日を入れればその日で保存する" do
    post events_path, params: { event: valid_params(end_at_date: "2099-03-15", end_at_time: "01:00") }

    expect(Event.find_by!(name: "定例会").end_at).to eq Time.zone.local(2099, 3, 15, 1, 0)
  end

  it "終了日が空で終了時刻が開始より前なら終了の欄にエラーを出す" do
    post events_path, params: { event: valid_params(end_at_date: "", end_at_time: "17:00") }

    expect(response).to have_http_status(:unprocessable_content)
    fieldset = form_html.at("fieldset.event-end")
    expect(fieldset.at(".field-error").text).to include "終了日時は開始日時より後にしてください"
  end

  it "終了時刻は今までどおり必須" do
    post events_path, params: { event: valid_params(end_at_date: "", end_at_time: "") }

    expect(response).to have_http_status(:unprocessable_content)
    expect(form_html.at("fieldset.event-end .field-error").text).to include "終了日時を入力してください"
  end

  it "エラーが無ければ aria-invalid を付けない" do
    get new_event_path

    expect(form_html.css("[aria-invalid]")).to be_empty
  end

  it "定員が 0 なら保存せず、定員の欄の下にエラーを出す" do
    expect do
      post events_path, params: { event: valid_params(max_size: "0") }
    end.not_to change(Event, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(form_html.at("#event_max_size_error").text).to eq "定員は1以上の値にしてください"
  end

  it "検証エラーのフラッシュは件数の要約にし、欄の文言を繰り返さない" do
    post events_path, params: { event: valid_params(name: "", max_size: "0") }

    alert = Nokogiri::HTML(response.body).at("main .alert-danger")
    expect(alert.text.squish).to eq "入力内容を確認してください（2件）"
  end

  it "更新の検証エラーも要約にする" do
    event = create(:event, organizer: user)

    patch event_path(event), params: { event: { name: "" } }

    expect(Nokogiri::HTML(response.body).at("main .alert-danger").text.squish).to eq "入力内容を確認してください（1件）"
  end
end

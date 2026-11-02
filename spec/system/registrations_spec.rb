require "rails_helper"

RSpec.describe "registrations", type: :system, js: true do
  describe "Signup form" do
    it "shows japanese labels inside the container" do
      visit signup_path

      within "div.container main" do
        %w[名前 メールアドレス パスワード パスワード（確認）].each do |label|
          expect(page).to have_field(label)
        end
        expect(page).to have_button("登録する")
      end
    end
  end

  describe "Signup" do
    before do
      visit signup_path
      fill_in :user_name, with: name
      fill_in :user_email, with: email
      fill_in :user_password, with: password
      fill_in :user_password_confirmation, with: password
      click_on '登録する'
    end

    context "when all in information" do
      let(:name) { "なまえ" }
      let(:email) { "example@email.com" }
      let(:password) { "test1234" }

      it "succeed to signup with message" do
        within "div.alert-success" do
          expect(page).to have_content("ユーザー登録しました")
        end
        expect(page).to have_link("ログアウト")
      end
    end

    context "display correct alert message" do
      let(:name) { 'なまえ' }
      let(:email) { "" }
      let(:password) { "" }

      it "fails to signup with alert message" do
        within "div.alert-danger" do
          expect(page).to have_content("Password を入力してください")
          expect(page).to have_content("Email を入力してください")
          expect(page).to have_content("Email の形式が不正です")
        end
      end
    end
  end
end

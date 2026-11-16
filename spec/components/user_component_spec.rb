# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserComponent, type: :component do
  it 'render show user' do
    render_inline(described_class.new(user: User.new(name: "Sakurai")))

    expect(page).to have_selector ".profile__name", text: "Sakurai"
    expect(page).to have_link "名前を編集"
    expect(page).not_to have_text "メールアドレス"
  end

  it 'Discord のアバターを飾りとして出す' do
    render_inline(described_class.new(user: User.new(name: "Sakurai", discord_user_id: "1", discord_avatar: "abc")))

    expect(page).to have_selector "img.avatar[alt='']"
  end
end

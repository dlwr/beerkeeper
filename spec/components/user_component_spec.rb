# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserComponent, type: :component do
  it 'render show user' do
    render_inline(described_class.new(user: User.new(name: "Sakurai")))

    expect(page).to have_selector "ul > li", text: "Sakurai"
    expect(page).not_to have_text "メールアドレス"
  end
end

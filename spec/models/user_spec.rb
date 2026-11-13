require 'rails_helper'

RSpec.describe User, type: :model do
  describe '.sign_in_with_discord' do
    let(:profile) { { "id" => "123", "username" => "taro", "global_name" => "Taro", "avatar" => "hash1" } }

    it '未登録の Discord アカウントならユーザーを作り、表示名を名前に入れる' do
      user = nil
      expect { user = User.sign_in_with_discord(profile) }.to change(User, :count).by(1)

      expect(user).to have_attributes(discord_user_id: "123", name: "Taro", discord_avatar: "hash1")
    end

    it '表示名が無ければユーザー名を名前に入れる' do
      user = User.sign_in_with_discord(profile.merge("global_name" => nil))

      expect(user.name).to eq "taro"
    end

    it '登録済みなら同じユーザーを返し、名前は上書きせずアバターだけ更新する' do
      existing = User.sign_in_with_discord(profile)
      existing.update!(name: "たろう")

      user = nil
      expect {
        user = User.sign_in_with_discord(profile.merge("global_name" => "New", "avatar" => "hash2"))
      }.not_to change(User, :count)

      expect(user).to eq existing
      expect(user.reload).to have_attributes(name: "たろう", discord_avatar: "hash2")
    end
  end

  describe '#avatar_url' do
    it 'Discord のアバターの URL を返す' do
      user = User.sign_in_with_discord("id" => "123", "username" => "taro", "avatar" => "hash1")

      expect(user.avatar_url).to eq "https://cdn.discordapp.com/avatars/123/hash1.png?size=64"
    end

    it 'アバターが無ければ nil' do
      expect(User.sign_in_with_discord("id" => "123", "username" => "taro", "avatar" => nil).avatar_url).to be_nil
      expect(create(:user).avatar_url).to be_nil
    end
  end

  describe '#participatable?' do
    subject { user.participatable?(event) }

    context 'when user is participating in the event' do
      let(:user) { FactoryBot.create(:user) }
      let(:event) { FactoryBot.create(:event) }
      let!(:participation) { FactoryBot.create(:participation, user: user, event: event) }

      it { is_expected.to be false }
    end

    context 'when user is not participating in the event' do
      let!(:user) { FactoryBot.create(:user) }
      let!(:event) { FactoryBot.create(:event) }

      it { is_expected.to be true }
    end
  end
end

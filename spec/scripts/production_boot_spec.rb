require 'spec_helper'
require 'open3'

RSpec.describe '本番モードの起動' do
  it 'Active Storage を読み込んでも image_processing の警告を出さない' do
    env = { 'RAILS_ENV' => 'production', 'SECRET_KEY_BASE_DUMMY' => '1' }
    output, status = Open3.capture2e(env, 'bin/rails', 'runner', 'ActiveStorage::Blob', chdir: File.expand_path('../..', __dir__))

    expect(status).to be_success, output
    expect(output).not_to include('image_processing')
  end
end

require 'spec_helper'
require 'open3'
require 'tmpdir'

RSpec.describe '本番のジョブのキュー' do
  let(:root) { File.expand_path('../..', __dir__) }

  def run_production(*args, storage:)
    env = { 'RAILS_ENV' => 'production', 'SECRET_KEY_BASE_DUMMY' => '1', 'RAILS_STORAGE_PATH' => storage }
    Open3.capture2e(env, 'bin/rails', *args, chdir: root)
  end

  it 'Solid Queue に載せ、db:prepare でキューの DB を作る' do
    Dir.mktmpdir do |storage|
      output, status = run_production('db:prepare', storage:)
      expect(status).to be_success, output

      output, status = run_production('runner', 'puts ActiveJob::Base.queue_adapter_name; puts SolidQueue::Job.connection_db_config.database; puts SolidQueue::Job.table_exists?', storage:)
      expect(status).to be_success, output
      expect(output.lines(chomp: true).last(3)).to eq [ 'solid_queue', File.join(storage, 'production_queue.sqlite3'), 'true' ]
    end
  end
end

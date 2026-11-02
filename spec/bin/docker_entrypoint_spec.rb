require "rails_helper"
require "open3"
require "tmpdir"

RSpec.describe "bin/docker-entrypoint" do
  let(:entrypoint) { Rails.root.join("bin/docker-entrypoint").to_s }

  def run_entrypoint(env)
    Dir.mktmpdir do |dir|
      log = File.join(dir, "calls.log")
      FileUtils.mkdir_p(File.join(dir, "bin"))
      FileUtils.mkdir_p(File.join(dir, "fakebin"))
      [ File.join(dir, "bin/rails"), File.join(dir, "fakebin/litestream") ].each do |path|
        File.write(path, "#!/bin/bash\necho \"$(basename \"$0\") $*\" >> #{log}\n")
        File.chmod(0o755, path)
      end

      path = env.key?("PATH") ? env["PATH"] : "#{dir}/fakebin:#{ENV.fetch('PATH')}"
      _, status = Open3.capture2e(env.merge("PATH" => path, "LD_PRELOAD" => ""), entrypoint, "./bin/rails", "server", "-b", "0.0.0.0", chdir: dir)
      expect(status).to be_success
      File.readlines(log, chomp: true)
    end
  end

  it "BUCKET_NAME が無ければ Litestream なしで起動する" do
    expect(run_entrypoint("BUCKET_NAME" => nil)).to eq [
      "rails db:prepare",
      "rails server -b 0.0.0.0"
    ]
  end

  it "BUCKET_NAME があればレプリカから復元してから、Litestream 経由で起動する" do
    expect(run_entrypoint("BUCKET_NAME" => "beerkeeper-dlwr-litestream")).to eq [
      "litestream restore -config /rails/config/litestream.yml -if-db-not-exists -if-replica-exists /rails/storage/production.sqlite3",
      "rails db:prepare",
      "litestream replicate -config /rails/config/litestream.yml -exec ./bin/rails server -b 0.0.0.0"
    ]
  end
end

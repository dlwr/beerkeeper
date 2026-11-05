begin
  require "rbs_rails/rake_task"

  RbsRails::RakeTask.new
rescue LoadError
end

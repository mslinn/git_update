require 'jekyll'
require_relative '../lib/pull'

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.filter_run_when_matching focus: true
  config.fail_fast = true
  # config.order = 'random'

  # See https://relishapp.com/rspec/rspec-core/docs/command-line/only-failures
  config.example_status_persistence_file_path = 'spec/status_persistence.txt'
end

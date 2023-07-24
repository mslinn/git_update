require 'jekyll'
require_relative '../lib/pull'

RSpec.configure do |config|
  config.disable_monkey_patching!

  config.fail_fast = true
  config.filter_run :focus
  # config.order = 'random'
  config.run_all_when_everything_filtered = true

  # See https://relishapp.com/rspec/rspec-core/docs/command-line/only-failures
  config.example_status_persistence_file_path = 'spec/status_persistence.txt'
end

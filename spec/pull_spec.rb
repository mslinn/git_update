require 'rspec'
require 'spec_helper'
require_relative '../lib/update'

RSpec.describe('Pull') do
  base = MslinnUtil.expand_env '$msp'
  base_fq = MslinnUtil.deref_symlink(base).to_s

  it 'fetches using ssh' do
    repo = Rugged::Repository.new base_fq
    remote = repo.remotes['origin']
    credentials = ssh_credentials repo
    success = remote.check_connection(:fetch, credentials: credentials)
    expect(success).to be true
  end
end

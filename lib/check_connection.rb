require 'pathname'
require 'rugged'

abort "Error: Rugged was not built with ssh support. Please see https://www.mslinn.com/git/4400-rugged.html".red \
  unless Rugged.features.include? :ssh

base = ARGV[0] || '.'
base_fq = Pathname.new(base).realpath.to_s
repo = Rugged::Repository.new base_fq
puts repo.inspect
remote = repo.remotes['origin']
puts "remote.name=#{remote.name}, remote.url=#{remote.url}, remote.fetch_refspecs=#{remote.fetch_refspecs}"

credentials = Rugged::Credentials::SshKey.new(
  username:   'git',
  passphrase: nil,
  privatekey: File.expand_path('~/.ssh/id_rsa'),
  publickey:  File.expand_path('~/.ssh/id_rsa.pub')
)
# credentials = Rugged::Credentials::SshKeyFromAgent.new(username: 'git')
puts credentials.inspect

success = remote.check_connection(:fetch, credentials: credentials)
puts "remote.check_connection(:fetch, credentials: credentials) returned #{success}"

# success = remote.fetch(credentials: credentials)
# puts "remote.fetch(credentials: credentials) returned #{success}"

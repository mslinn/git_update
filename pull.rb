require 'rugged'

def update_via_rugged(dir_name)
  repo = Rugged::Repository.new dir_name

  pull repo
end

def ssh_credentials
  Rugged::Credentials::SshKey.new(
    username: 'mslinn',
    passphrase: nil,
    publickey: File.expand_path("~/.ssh/id_rsa.pub"),
    privatekey: File.expand_path("~/.ssh/id_rsa")
  )
end

def user_password_credentials
  Rugged::Credentials::UserPassword.new(
    username: 'mslinn',
    password: 'blah'
  )
end

# Mike Slinn translated into Ruby from this Python code:
# https://github.com/MichaelBoselowitz/pygit2-examples/blob/68e889e50a592d30ab4105a2e7b9f28fac7324c8/examples.py#L48-L78
def pull(repo, remote_name='origin')
  remote = repo.remotes[remote_name]
  puts "remote.url=#{remote.url}"
  credentials = remote.url.start_with?('https') ? user_password_credentials : ssh_credentials
  remote.fetch(credentials: credentials)
  remote_master_id = repo.ref('refs/remotes/origin/master').target
  merge_result, _ = repo.merge_analysis(remote_master_id)

  case merge_result
  when :up_to_date
    return

  when :fastforward
    repo.checkout_tree(repo.get(remote_master_id))
    master_ref = repo.lookup_reference('refs/heads/master')
    master_ref.set_target(remote_master_id)
    repo.head.set_target(remote_master_id)

  when :normal
    repo.merge(remote_master_id)
    raise "Problem: merging updates for #{repo.name} encountered conflicts" if repo.index.conflicts?

    user = repo.default_signature
    tree = repo.index.write_tree
    repo.create_commit 'HEAD', user, user, 'Merge', tree,
                        [repo.head.target, remote_master_id]
    repo.state_cleanup
  else
    raise AssertionError 'Unknown merge analysis result'
  end
end

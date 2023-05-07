require 'rugged'

@select_credentials = proc do |url, username, allowable_credential_types|
  puts "Computing credentials for #{username} at #{url}; allowable credential types are: #{allowable_credential_types}"
  if url.start_with? 'https'
    user_password_credentials
  elsif url.start_with? 'git@github.com'
    begin
      Rugged::Credentials::SshKeyFromAgent.new(username: 'git')
    rescue StandardError => e
      puts "SSH Agent not found, trying manual ssh config: #{e}"
      ssh_credentials(repo)
    end
  end
end

def update_via_rugged(dir_name)
  repo = Rugged::Repository.new dir_name
  pull(repo)
end

def ssh_credentials(repo)
  Rugged::Credentials::SshKey.new(
    username:   repo.config.username,
    passphrase: nil,
    publickey:  File.expand_path("~/.ssh/id_rsa.pub"), # TODO: figure out which cert to use
    privatekey: File.expand_path("~/.ssh/id_rsa")
  )
end

# See https://learn.microsoft.com/en-us/azure/devops/repos/git/set-up-credential-managers
def user_password_credentials
  # The values of username and password are ignored for public repos on GitHub, GitLab, Bitbucket, etc.
  # However, the parameters must be provided even though the values are ignored
  Rugged::Credentials::UserPassword.new(username: '', password: '')
end

def pull(repo, remote_name = 'origin')
  remote = repo.remotes[remote_name]
  refspec_str = 'refs/remotes/origin/master'
  begin
    remote.check_connection(:fetch, credentials: @select_credentials)
    remote.fetch(refspec_str, credentials: @select_credentials)
  rescue Rugged::NetworkError => e
    puts e.full_message
  end
  remote_master_id = repo.ref(refspec_str).target
  merge_result, = repo.merge_analysis(remote_master_id)

  case merge_result
  when :up_to_date
    # Nothing needs to be done

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
    repo.create_commit 'HEAD', user, user, 'Merge', tree, [repo.head.target, remote_master_id]
    repo.state_cleanup
  else
    raise AssertionError 'Unknown merge analysis result'
  end
end

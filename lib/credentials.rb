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
      ssh_credentials
    end
  end
end

def ssh_credentials
  Rugged::Credentials::SshKey.new(
    username:   'git',
    passphrase: nil,
    publickey:  File.expand_path('~/.ssh/id_rsa.pub'), # TODO: figure out which cert to use
    privatekey: File.expand_path('~/.ssh/id_rsa')
  )
end

# See https://learn.microsoft.com/en-us/azure/devops/repos/git/set-up-credential-managers
def user_password_credentials
  # The values of username and password are ignored for public repos on GitHub, GitLab, Bitbucket, etc.
  # However, the parameters must be provided even though the values are ignored
  Rugged::Credentials::UserPassword.new(username: '', password: '')
end

require 'rainbow/refinement'
require 'rugged'

using Rainbow

# Allowable credential types:
#   :plaintext       - A vanilla user/password request
#   :ssh_custom      - An SSH key-based authentication request with a custom signature
#   :default         - An NTLM/Negotiate-based authentication request.
#   :ssh_interactive - An SSH interactive authentication request
#   :ssh_memory      - Credentials read from memory. Only available for libssh2+OpenSSL.
#                      An SSH key-based authentication request. Allows credentials to be read
#                      from memory instead of files. Note that because of differences in crypto
#                      backend support, it might not be functional.
#   :username        - Username-only authentication request. Used as a pre-authentication step if
#                      the underlying transport (eg. SSH, with no username in its URL) does not
#                      know which username to use.
# See https://github.com/libgit2/libgit2/blob/v1.6.4/include/git2/credential.h#L27-L79

@select_credentials = proc do |url, username, allowable_credential_types|
  # allowable_credential_types is an array of symbols that often contains :ssh_key or :username.
  puts "  Computing credentials for #{username} at #{url}; allowable credential types are: #{allowable_credential_types}".blue.bright
  if url.start_with?('https') # && allowable_credential_types.include?(:plaintext)
    # The values of username and password are ignored for public repos on GitHub, GitLab, Bitbucket, etc.
    # However, the parameters must be provided even though the values are ignored
    # See https://learn.microsoft.com/en-us/azure/devops/repos/git/set-up-credential-managers
    Rugged::Credentials::UserPassword.new(username: '', password: '')
  elsif url.start_with?('git@') && allowable_credential_types.include?(:ssh_key)
    begin
      Rugged::Credentials::SshKey.new(
        username:   'git',
        passphrase: nil,
        publickey:  File.expand_path('~/.ssh/id_rsa.pub'), # TODO: figure out which cert to use
        privatekey: File.expand_path('~/.ssh/id_rsa')
      )
    rescue StandardError => e
      puts "  SshKey credentials failed, trying ssh agent: #{e.full_message}".blue.bright
      begin
        Rugged::Credentials::SshKeyFromAgent.new(username: 'git')
      rescue StandardError => e
        puts "Ssh agent failed: #{e.full_message}".red
        raise e
      end
    end
  else
    puts "  Error: Unknown credential types: #{allowable_credential_types}".red
  end
end

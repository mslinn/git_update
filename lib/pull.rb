require 'rainbow/refinement'
require 'rugged'
require_relative 'credentials'

class GitUpdate
  using Rainbow

  abort "Error: Rugged was not built with ssh support. Please see https://www.mslinn.com/git/4400-rugged.html".red \
    unless Rugged.features.include? :ssh

  # Just updates the default branch
  def pull(repo, remote_name = 'origin') # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    remote = repo.remotes[remote_name]
    unless remote.respond_to? :url
      puts "  Remote '#{remote_name}' has no url defined. Skipping this repository."
      return
    end
    puts "  remote.url=#{remote.url}".yellow
    default_branch = repo.head.name.split('/')[-1]
    refspec_str = "refs/remotes/#{remote_name}/#{default_branch}"
    begin
      success = remote.check_connection(:fetch, credentials: select_credentials)
      unless success
        puts "  Error: remote.check_connection failed.".red
        return
      end
      remote.fetch(refspec_str, credentials: select_credentials)
    rescue Rugged::NetworkError => e
      puts "  Error: #{e.full_message}".red
    end
    abort "Error: repo.ref(#{refspec_str}) for #{remote} is nil".red if repo.ref(refspec_str).nil?
    remote_master_id = repo.ref(refspec_str).target
    merge_result, = repo.merge_analysis(remote_master_id)

    case merge_result
    when :up_to_date
      # Nothing needs to be done
      puts "  Repo at '#{repo.workdir}' was already up to date.".blue.bright

    when :fastforward
      repo.checkout_tree(repo.get(remote_master_id))
      master_ref = repo.lookup_reference('refs/heads/master')
      master_ref.set_target(remote_master_id)
      repo.head.set_target(remote_master_id)

    when :normal
      # See https://www.pygit2.org/merge.html#pygit2.Repository.merge
      repo.merge(remote_master_id) #pygit2 has this method, but rugged does not
      raise "Problem: merging updates for #{repo.name} encountered conflicts".red if repo.index.conflicts?

      user = repo.default_signature
      tree = repo.index.write_tree
      repo.create_commit 'HEAD', user, user, 'Merge', tree, [repo.head.target, remote_master_id]
      repo.state_cleanup
    else
      raise AssertionError 'Unknown merge analysis result'.red
    end
  end

  def update_via_rugged(dir_name)
    repo = Rugged::Repository.new dir_name
    pull repo
  rescue StandardError => e
    puts "Ignoring #{dir_name} due to error: .#{e.full_message}".red
  end
end

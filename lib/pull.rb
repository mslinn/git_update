require 'rugged'
require_relative 'credentials'

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

def update_via_rugged(dir_name)
  repo = Rugged::Repository.new dir_name
  pull(repo)
end

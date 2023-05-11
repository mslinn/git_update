require 'rugged'

abort "Error: Rugged was not built with ssh support. Please see https://www.mslinn.com/git/4400-rugged.html".red unless Rugged.features.include? :ssh

def fetch(repo)
  remote = repo.remotes['origin']
  remote.connect(:fetch) do |r|
    r.download
    r.update_tips!
  end
end

def merge(repo)
  merge_index = repo.merge_commits(
    Rugged::Branches.lookup(repo, 'master').tip,
    Rugged::Branches.lookup(repo, 'origin/master').tip
  )

  raise 'Conflict detected!' if merge_index.conflicts?

  merge_commit = Rugged::Commit.create(repo, {
    parents:    [
                  Rugged::Branches.lookup(repo, 'master').tip,
                  Rugged::Branches.lookup(repo, 'origin/master').tip
                ],
    tree:       merge_index.write_tree(repo),
    message:    'Merged `origin/master` into `master`',
    author:     { name: "User", email: "example@test.com" },
    committer:  { name: "User", email: "example@test.com" },
    update_ref: 'master',
  })
end

def pull
  repo = Rugged::Repository.new dir_name
  fetch repo
  merge repo
end

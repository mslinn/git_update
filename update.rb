require 'rugged'
require_relative 'util'

@threads = []

def process_dir(dir_name)
  return if File.exist? "#{dir_name}/.ignore"

  if Dir.exist? "#{dir_name}/.git"
    @threads << Thread.new { update dir_name }
    return
  end
  Dir['dir_name/**'].each do |entry|
    process_dir entry if File.directory? entry
  end
end

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
    update_ref: 'master'
  })
end

def update(dir_name)
  repo = Rugged::Repository.new dir_name
  fetch repo
  merge repo
end

abort "Error: no directory specified" if ARGV.empty?

base = MslinnUtil.expand_env ARGV[0]
process_dir MslinnUtil.deref_symlink(base).to_s
@threads.each(&:join)

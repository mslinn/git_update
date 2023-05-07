require_relative 'util'

@threads = []

def process_dir(dir_name)
  if File.exist? "#{dir_name}/.ignore"
    puts "Ignoring #{dir_name}"
    return
  end

  if Dir.exist? "#{dir_name}/.git"
    @threads << Thread.new { update dir_name }
    return
  end

  puts "Processing #{dir_name}"
  Dir["#{dir_name}/*"].each do |entry|
    process_dir(entry) if File.directory? entry
  end
end

def update(dir_name)
  Dir.chdir(dir_name) do
    Updating "git pull #{dir_name}"
    `git pull`
  end
end

abort "Error: no directory specified" if ARGV.empty?

base = MslinnUtil.expand_env ARGV[0]
process_dir MslinnUtil.deref_symlink(base).to_s
@threads.each(&:join)

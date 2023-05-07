require_relative 'util'

@threads = []

def process_dir(dir_name)
  if File.exist? "#{dir_name}/.ignore"
    puts "Ignoring #{dir_name}"
    return
  end

  if Dir.exist? "#{dir_name}/.git"
    update dir_name
    return
  end

  puts "Processing #{dir_name}"
  Dir["#{dir_name}/*"].each do |entry|
    process_dir(entry) if File.directory? entry
  end
end

def update(dir_name)
  Dir.chdir(dir_name) do
    @threads << Thread.new do
      puts "Updating #{dir_name}"
      puts `git pull`.chomp
    end
  end
end

abort "Error: no directory specified" if ARGV.empty?

ARGV.each do |arg|
  base = MslinnUtil.expand_env arg
  process_dir MslinnUtil.deref_symlink(base).to_s
end
@threads.each(&:join)

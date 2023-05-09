require_relative 'util'
require_relative 'pull'

@threads = []

def process_dir(dir_name)
  if File.exist? "#{dir_name}/.ignore"
    puts "Ignoring #{dir_name}"
    return
  end

  if Dir.exist? "#{dir_name}/.git"
    puts "Updating #{dir_name}"
    update_via_rugged dir_name
    return
  end

  puts "Processing directory #{dir_name}"
  Dir["#{dir_name}/*"].each do |entry|
    process_dir(entry) if File.directory? entry
  end
end

def update_via_cli(dir_name)
  Dir.chdir(dir_name) do
    @threads << Thread.new do
      puts "Updating #{dir_name}"
      puts `git pull`.chomp
    end
  end
end

if $PROGRAM_NAME == __FILE__
  abort "Error: no directory specified" if ARGV.empty?

  ARGV.each do |arg|
    base = MslinnUtil.expand_env arg
    process_dir MslinnUtil.deref_symlink(base).to_s
  end
  @threads.each(&:join)
end
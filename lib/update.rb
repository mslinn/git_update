require 'concurrent'
require_relative 'util'
require_relative 'pull'

# libgit2 v1.6.3 is not completely threadsafe, and fetch/merge is definitely not threadsafe
# A pool size of 1 allows the main thread (running process_dir) and one update thread to run concurrently
@pool = Concurrent::FixedThreadPool.new(1, max_queue: 1000)
@max_queue_length = 0
puts "#{@pool.max_queue} tasks are allowed to wait in the thread pool's work queue."

def max(a, b)
  a > b ? a : b
end

def process_dir(dir_name)
  if File.exist? "#{dir_name}/.ignore"
    puts "Ignoring #{dir_name}"
    return
  end

  if Dir.exist? "#{dir_name}/.git"
    @pool.post do
      puts "Updating #{dir_name}"
      update_via_rugged dir_name
    end
    puts "  #{@pool.queue_length} tasks are currently waiting in the thread pool's work queue."
    @max_queue_length = @pool.queue_length if @pool.queue_length > @max_queue_length
    return
  end

  puts "Processing directory #{dir_name}"
  Dir["#{dir_name}/*"].each do |entry|
    process_dir(entry) if File.directory? entry
  end
end

def update_via_cli(dir_name)
  Dir.chdir(dir_name) do
    @pool.post do
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
  puts "#{@pool.completed_task_count} tasks were executed by the thread pool."
  puts "A maximum of #{@max_queue_length} tasks waited in the queue."
end

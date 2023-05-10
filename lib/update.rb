require 'concurrent'
require 'rainbow/refinement'
require_relative 'util'
require_relative 'pull'

using Rainbow

# libgit2 v1.6.3 is not completely threadsafe, and fetch/merge is definitely not threadsafe
# A pool size of 1 allows the main thread (running process_dir) and one update thread to run concurrently
@pool = Concurrent::FixedThreadPool.new(1, max_queue: 1000)
@max_queue_length = 0
puts "#{@pool.max_queue} tasks are allowed to wait in the thread pool's work queue.".blue.bright

def process_dir(dir_name)
  if File.exist? "#{dir_name}/.ignore"
    puts "Ignoring #{dir_name}".yellow
    return
  end

  if Dir.exist? "#{dir_name}/.git"
    @pool.post do
      puts "Updating #{dir_name}".green
      update_via_rugged dir_name
    end
    puts "  #{@pool.queue_length} tasks are currently waiting in the thread pool's work queue.".blue.bright
    @max_queue_length = @pool.queue_length if @pool.queue_length > @max_queue_length
    return
  end

  puts "Processing directory #{dir_name}".cyan
  Dir["#{dir_name}/*"].each do |entry|
    process_dir(entry) if File.directory? entry
  end
end

def update_via_cli(dir_name)
  Dir.chdir(dir_name) do
    @pool.post do
      puts "Updating #{dir_name}".green
      puts `git pull`.chomp.cyan
    end
  end
end

if $PROGRAM_NAME == __FILE__
  abort "Error: no directory specified".red if ARGV.empty?

  ARGV.each do |arg|
    base = MslinnUtil.expand_env arg
    process_dir MslinnUtil.deref_symlink(base).to_s
  end
  puts "#{@pool.completed_task_count} tasks were executed by the thread pool.".black.bg(:green)
  puts "A maximum of #{@max_queue_length} tasks waited in the queue.".black.bg(:green)
end

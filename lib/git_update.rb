require 'etc'
require 'parallel'
require 'rainbow/refinement'
require_relative 'git_update/version'
require_relative 'util'
require_relative 'pull'

class GitUpdate
  using Rainbow

  def initialize
    # libgit2 v1.6.3 is not completely threadsafe, and fetch/merge is definitely not threadsafe.
    # Git-pull is also not threadsafe, so it needs to run in its own processes.
    # A fixed pool size allows the main thread (running process_dir)
    # and several update threads to run concurrently
    @max_processes = Etc.nprocessors > 1 ? Etc.nprocessors - 1 : 1
    puts "#{@max_processes} processes can be launched"

    Parallel.each(['a','b','c'], in_processes: @max_processes) do |one_letter|
      SomeClass.expensive_calculation(one_letter)
    end

    @pool = Concurrent::FixedThreadPool.new(1, max_queue: 1000)
    @max_queue_length = 0
    puts "#{@pool.max_queue} tasks are allowed to wait in the thread pool's work queue.".blue.bright
  end

  def self.command_update
    abort "Error: at least one directory name must be specified".red if ARGV.empty?

    git_update = GitUpdate.new
    ARGV.each do |arg|
      base = MslinnUtil.expand_env arg
      git_update.process_dir MslinnUtil.deref_symlink(base).to_s
    end
    at_exit do
      puts "#{git_update.pool.completed_task_count} tasks were executed by the thread pool.".black.bg(:green)
      puts "A maximum of #{git_update.max_queue_length} tasks waited in the queue.".black.bg(:green)
    end
  end

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
end

GitUpdate.command_update if $PROGRAM_NAME == __FILE__

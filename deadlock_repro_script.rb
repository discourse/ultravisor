require "ultravisor"

counter = 0

class FakeRunner # Nefario::MobyDerpRunner
  def initialize; end

  def run
    puts "FakeMobyDerpRunner started. Calling process_castcall_loop"
    process_castcall_loop
  end

  def do_something
    puts "do_somthing called. Raising exception"
    raise "A Fake Exception"
  end
end

class FakeDirWatcher # Nefario::ConfigDirWatcher
  def initialize(ultravisor:)
    @ultravisor = ultravisor
  end

  def run
    puts "FakeConfigDirWatcher started. Making call to FakeRunner every second"
    loop do
      @ultravisor[:fake_runner].call.do_something
    ensure
      counter += 1
      puts "this should be printed every second"
    end
  end
end

u = Ultravisor.new(logger: Logger.new(STDOUT))
u.add_child(id: :fake_runner, klass: FakeRunner, method: :run, enable_castcall: true)
u.add_child(id: :fake_dir_watcher, klass: FakeDirWatcher, method: :run, args: [{ ultravisor: u }])

Thread.new do
  sleep 10
  puts
  puts
  next puts "Yay the bug is fixed" if counter >= 1
  puts "We're stuck. Printing backtraces"
  puts "-"*60
  Thread.list.reject{ |t| t == Thread.current }.each do |t|
    puts t.inspect
    puts
    puts t.backtrace.join("\n")
    puts "-"*60
  end
end

u.run

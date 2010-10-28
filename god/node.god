app_root  = "/Users/antoniomarques/Work/Personal/codingthougths.com"


God.watch do |w|
  w.name     = "node-god-instance"
  w.group    = 'node-god'
  w.interval = 15.seconds
  
  w.start  = lambda { `node /Users/antoniomarques/Work/Personal/codingthougths.com/app.js`}
  w.stop  = "env killall node"
  
  w.uid = ENV['USER']
  
  # restart if memory gets too high
  w.transition(:up, :restart) do |on|
    on.condition(:memory_usage) do |c|
      c.above = 300.megabytes
      c.times = 2
    end
  end

  # determine the state on startup
  w.transition(:init, { true => :up, false => :start }) do |on|
    on.condition(:process_running) do |c|
      c.running = true
    end
  end

  # determine when process has finished starting
  w.transition([:start, :restart], :up) do |on|
    on.condition(:process_running) do |c|
      c.running = true
      c.interval = 5.seconds
    end

    # failsafe
    on.condition(:tries) do |c|
      c.times = 5
      c.transition = :start
      c.interval = 5.seconds
    end
  end

  # start if process is not running
  w.transition(:up, :start) do |on|
    on.condition(:process_running) do |c|
      c.running = false
    end
  end
end

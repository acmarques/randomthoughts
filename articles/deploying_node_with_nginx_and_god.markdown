Title: Deploying Node.js apps with Nginx and God
Author: Antonio Marques
Date: Sun Oct 31 2010 12:38:25 GMT-0700 (PDT)
Node: v0.2.4
Categories: nodejs, nginx, god

This article explains how to set up a server to host [node.js][] applications. As node.js processes can't be run as daemons - except by using [Upstart][], which by now is stable only for Ubuntu; [more info here][] - the idea is to use a web server ([nginx][]) to proxy connections to the node.js process and [God][] to manage and monitor the node.js process running the application.  

I'll use a Debian Lenny 5.0 VM in this article, but the steps performed and packages required should be similar in other distros.

Lets start by creating a simple application. Edit `/var/www/apps/hello_world.js` and paste in the _Hello World_ app.

    var http = require("http");
    http.createServer(function (request, response) {
      response.writeHead(200, {"Content-Type": "text/plain"});
      response.write("Hello World\n");
      response.close();
    }).listen(3000);

Notice that this process will listen on __port 3000__.

## Packages

The following packages are required: 

    apt-get install nginx python build-essential libssl-dev curl ruby ruby1.8-dev psmisc


## Node.js

Download and build Node.js:

    cd /usr/local
    wget http://nodejs.org/dist/node-v0.2.4.tar.gz
    tar -zxvf node-v0.2.4.tar.gz
    cd node-v0.2.4/
    ./configure && make && make install
    
Then check if it is working correctly:

    node -v
    => v0.2.4

## Configuring Nginx to proxy requests

Create the nginx virtual host file in `/etc/nginx/sites-available/helloworld` and paste in the following configuration:

    upstream app {
      server 127.0.0.1:3000;
    }

    server {
      listen 0.0.0.0:80;
      server_name www.helloworld.com helloworld.com;
      access_log /var/log/nginx/helloworld.log;

      location / {
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host;
        proxy_set_header X-NginX-Proxy true;

        proxy_pass http://app;
        proxy_redirect off;
      }
    }

Remember to add __helloworld.com__ to your `/etc/hosts` pointing to your server's IP address.

Next create a symlink to enable this virtual host:

    cd /etc/nginx/sites-enabled/
    ln -s /etc/nginx/sites-available/helloworld helloworld
    
And then run `/etc/init.d/nginx restart`. 

## Trying things out - pt. 1

You can now check if your virtual host is working as expected by starting up your node.js app and trying to access it through nginx.
Let's first run the _Hello World_ app:

    cd /var/www/apps/
    node hello_world.js

Now if you access __http://www.helloworld.com__ (remember to include it in your `/etc/hosts`) your should see the __Hello World__ page!
If you don't, review the previous steps and try to figure out what went wrong. Don't go any further without making this work!

Now that nginx is working correctly, we need to configure [God][] to monitor the Node.js process.


## God

_[God][] is an easy to configure, easy to extend monitoring framework written in Ruby_. 

It is distributed as a ruby gem, so before installing God we need to install [RubyGems][]:

    cd /usr/local
    wget http://rubyforge.org/frs/download.php/70696/rubygems-1.3.7.tgz
    cd rubygems-1.3.7/
    ruby setup.rb 

Now we can install God:

    sudo gem install god
        
Then check if it is working correctly:

    god -v
    => Version 0.11.0    
    
#### God configuration file

God requires one (or more) configuration file(s) to work. This configuration file tells God what is the process to monitor, what are the commands to start and stop the process, and in which situations God should restart the process.  
The following configuration file tells God to restart the Node process if:

  - it crashes
  - memory usage gets above 100 Mb
  - CPU usage gets above 50%  
  
Now it's time to edit `/var/www/god/node.god` and paste in the following snippet.

    app_root  = "/var/www/apps/"

    God.watch do |w|
      w.name     = "node-god-instances"
      w.group    = 'node-god'
      w.interval = 5.seconds
  
      w.start  = "env node #{app_root}/hello_world.js"
      w.stop  = "env killall node"
  
      w.uid = ENV['USER']
  
      w.pid_file = File.join(app_root, "node-monitor.pid")
      w.behavior(:clean_pid_file)
  
      w.start_if do |start|
        start.condition(:process_running) do |c|
          c.interval = 5.seconds
          c.running = false
        end
      end
  
      w.restart_if do |restart|
        restart.condition(:memory_usage) do |c|
          c.above = 100.megabytes
          c.times = [3, 5] # 3 out of 5 intervals
        end
  
        restart.condition(:cpu_usage) do |c|
          c.above = 50.percent
          c.times = 5
        end
      end
  
      # lifecycle
      w.lifecycle do |on|
        on.condition(:flapping) do |c|
          c.to_state = [:start, :restart]
          c.times = 5
          c.within = 5.minute
          c.transition = :unmonitored
          c.retry_in = 10.minutes
          c.retry_times = 5
          c.retry_within = 2.hours
        end
      end

    end
   
## Trying things out - pt. 2  

Now let's check if God is correctly configured to monitor the Hello World app. In the shell, type:

    sudo god -c /var/www/god/node-monitor -D

And check the log messages.  

God should be running as well as the Hello World app, that has been started by God. To test if God is correctly monitoring the node.js process, try killing it to check if God respawns it automatically:

    kill `ps -e -o pid,command | grep node -m 1 | awk '{ print $1; }'`

If the node.js process is still running, God is correctly monitoring! Nice!

## Last details
  
To finish this configuration, let's just add an initialization script to start God in the server's startup.    

Edit `/etc/init.d/node-monitor` and paste in the following:

    APP_ROOT=/var/www/

    PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/var/lib/gems/1.8/bin
    DAEMON=/usr/bin/god
    DAEMON_ARGS="-c $APP_ROOT/god/node.god"
    NAME=node-monitor
    DESC=node-monitor
    PIDFILE=/var/run/node-monitor.pid

    test -x $DAEMON || exit 0
    test -x $DAEMONBOOTSTRAP || exit 0

    set -e

    case "$1" in
      start)
    		echo -n "Starting $DESC: "
    	  $DAEMON $DAEMON_ARGS -P /var/run/god.pid -l /var/log/god.log
    	  RETVAL=$?
    	  echo "God started"
    	;;
      stop)
    		echo -n "Stopping $DESC: "
    	  kill `cat /var/run/god.pid`
    	  kill `ps -e -o pid,command | grep node -m 1 | awk '{ print $1; }'`
    	  RETVAL=$?
    	  echo "God stopped"
    	;;

      restart|force-reload)
    	${0} stop
    	${0} start
    	;;
      *)
    	echo "Usage: /etc/init.d/$NAME {start|stop|restart|force-reload}" >&2
    	exit 1
    	;;
    esac

    exit 0
    
And then configure the service to start in the machine boot:    
    
    update-rc.d /etc/init.d/node-monitor defaults    
    

Thats all, now you have a stable node.js production environment. This is the setup I use in this blog, and by now I'm very satisfied. Any suggestions or thougts are welcome, please leave a comment!

[node.js]: http://nodejs.org/
[nginx]: http://nginx.org/
[God]: http://god.rubyforge.org/
[Upstart]: http://upstart.ubuntu.com/
[more info here]: http://howtonode.org/deploying-node-upstart-monit
[RubyGems]: https://rubygems.org/
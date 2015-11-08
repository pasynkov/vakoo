##Installation

```sh
$ npm install --save vakoo
```

##Project architecture

```javascript
  _ProjectName
  __node_modules
  ___vakoo
  __config //config folder, required
  ___default //default configs, required
  ____config.coffee //main config file
  ___stable //stable configs
  ____config.coffee //main stable configs, can rewrite credentials of main-config
  __controllers //web controllers folder, non required
  ___sumple_controller.coffee
  __scripts //some scipts, classes, its your choose
  ___some_script.coffee
  __crons //folder for cron tasks
  ___some_task.coffee
  __initializers //initializers, runned after db-connection, and before scripts/web-server/crons started
  ___some_initializer.coffee
  
```

##Config
```coffee-script
module.exports = { #config-file
  storage: #enable database
    enable: true #non-required, but if false - db woldn't connected
    
    redis: #redis-config
      main: #first connection must be called `main`
        enable: true
      remote: #second and other connections
        enamble: true
        host: "redis.host.com"
        password: "somepass"
    
    mongo: #`main` not required if connections is only one    
      enable: true
      name: "dbname"
      username: "dbuser"
      password: "dbpassword"
      host: "mongo.host.com"
      port: 27017
      
    mysql: 
      host: "db.vakoo.ru"
      user: "dbuser"
      password: "dbpassword"
      database: "dbname"
      
  web: #web-server config
    enable: true
    static: "static" #static-folder
    cacheStatic: true #enable static-cache memory-based
    port: 8090 #webserver port
    
  loggers: 
    SimpleLogger: {}
    
  initializers: [
    "myinitializer"
  ]
  
  crons: [
    {
      name: "My Simple Cron"
      time: "*/5 * * * * *" #cron time, at this - once of 5 seconds
      script: "cron_script_file"
    }
  ]
      
}
```

##Usage

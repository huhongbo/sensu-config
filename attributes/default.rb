
default["plugin_files"] = ["network.rb", "load.rb", "system_default.rb", 
  "hpux-ruby-memory.rb", "system_user_cpu_used.rb", "disk_tps.rb", "scsistat_hba.rb"]
  
default["handler_files"] = ["client-log_del.rb"]

default["conf_files"] = ["client.json", "check_cpu.json"]

default["graphite"]["url"] = "graphite.zj.chinamobile.com"
default["graphite"]["ser_ip"] = "10.70.181.217"


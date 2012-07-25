#
# Cookbook Name:: sensu-config
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
root_group = value_for_platform(
  ["aix"] => { "default" => "system" },
  ["hpux"] => { "default" => "sys" },
  "default" => "root"
)

directory "/etc/sensu" do
  action :create
end
unless node["platform"] == "hpux"
  directory "/etc/init.d" do
    action :create
  end
else
  directory "/sbin/init.d" do
    action :create
  end    
end

directory "/var/log" do
  action :create
end


if node["os"] == "aix"
  directory "/var/chef/run" do
    owner "root"
    group "system"
    mode 0755
    action :create
  end
else
  directory "/var/run" do
    action :create
  end
end



%w{ conf.d handlers plugins }.each do |dir|
  directory "/etc/sensu/#{dir}" do
    mode 0775
    owner "root"
    group root_group
    action :create
    recursive true
  end
end

directory "/etc/sensu/plugins/system" do
  action :create
end



sensu_dir = "/etc/sensu"
# remote copy files conf.d  
remote_directory "/etc/sensu/conf.d" do
  source "sensu/conf.d"
  recursive true
  notifies :restart, "service[sensu_client]", :delayed
end

remote_directory "/etc/sensu/handlers" do
  source "sensu/handlers"
  recursive true
  files_mode 0755
end

remote_directory "/etc/sensu/plugins" do
  source "sensu/plugins"
  files_mode 0755
  recursive true
end

# remote config.json
cookbook_file "/etc/sensu/config.json" do
  source "sensu/config.json"
  notifies :restart, "service[sensu_client]", :delayed
end

cookbook_file "/etc/sensu/redis-event.rb" do
  source "sensu/redis-event.rb"
end


=begin
sensu_config = data_bag('sensu-config')
sensu_config.each do |sensu|
  content_json = data_bag_item("sensu-config","#{sensu}").reject do |key,value|
    %w[id chef_type data_bag].include?(key)
  end
  if sensu == "config"
    file "#{sensu_dir}/config.json" do
      content content_json.to_json
      notifies :run, "execute[restart]", :immediately
    end
  end
  
  if sensu != "config"
    file "#{sensu_dir}/conf.d/#{sensu}.json" do
      content content_json.to_json
    end 
  end
end  
=end



# template client.json erb
node["conf_files"].each do |conf|
  template "#{sensu_dir}/conf.d/#{conf}" do
    source "conf.d/#{conf}.erb"
    mode 0644
    notifies :restart, "service[sensu_client]", :delayed
  end
end

# temp system erb
node["plugin_files"].each do |pluginfile|
  template "/etc/sensu/plugins/system/#{pluginfile}" do
    source "plugins/system/#{pluginfile}.erb"
    mode 775
  end
end

#node["handler_files"].each do |handlerfile|
#  cookbook_file "/etc/sensu/handlers/#{handlerfile}" do
#    source "handlers/#{handlerfile}"
#    mode 775
#  end
#end

#service config


conf_dir = value_for_platform(
["aix", "ubuntu"] => {"default" => "/etc/init.d"},
["hpux"] => { "default" => "/sbin/init.d" },
"default" => "/etc/init.d"
)
template "#{conf_dir}/sensu_client" do
  source "sensu_client.erb"
  mode 0755
end

pattern_conf = value_for_platform(
["hpux", "ubuntu"] => {"default" => "sensu-client"},
"default" => "sensu-client"
)

service "sensu_client" do
  if (platform?("hpux"))
    provider Chef::Provider::Service::Hpux
  elsif (platform?("aix"))
    provider Chef::Provider::Service::Init
  elsif (platform?("ubuntu"))
    Chef::Provider::Service::Init::Debian
  end
  #supports :restart => true  
  action :start
end

# check sensu client Process status

if File.exist?("/var/log/sensu-client.log")
  file_time = File.mtime("/var/log/sensu-client.log").to_i
  time_now = Time.now.to_i
  time_value = (time_now - file_time) / 60
  unless time_value < 3
    service "sensu_client" do
      if (platform?("hpux"))
        provider Chef::Provider::Service::Hpux
      elsif (platform?("aix"))
        provider Chef::Provider::Service::Init
      end  
        action :restart
    end
  end
end







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
    mode 775
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
template "#{sensu_dir}/conf.d/client.json" do
  source "client.json.erb"
  mode 0644
  notifies :restart, "service[sensu_client]", :delayed
end

sensu_config = data_bag('sensu-config')
sensu_config.each do |sensu|
  content_json = data_bag_item("sensu-config","#{sensu}").reject do |key,value|
    %w[id chef_type data_bag].include?(key)
  end
  unless sensu == "config"
    file "#{sensu_dir}/conf.d/#{sensu}.json" do
      content content_json.to_json
      notifies :restart, "service[sensu_client]", :delayed
    end
  else
    file "#{sensu_dir}/config.json" do
      content content_json.to_json
      notifies :restart, "service[sensu_client]", :delayed
    end
  end
end
  
node["plugin_files"].each do |pluginfile|
  template "/etc/sensu/plugins/system/#{pluginfile}" do
    source "plugins/system/#{pluginfile}.erb"
    mode 775
  end
end

node["handler_files"].each do |handlerfile|
  cookbook_file "/etc/sensu/handlers/#{handlerfile}" do
    source "handlers/#{handlerfile}"
    mode 775
  end
end

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
  end  
    action :start
end

# check sensu client Process status
file_time = File.atime("/var/log/sensu-client.log").strftime("%Y%m%d%H%M%S")
time_now = Time.now.strftime("%Y%m%d%H%M%S") 
time_value = (time_now.to_i - file_time.to_i)/60

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








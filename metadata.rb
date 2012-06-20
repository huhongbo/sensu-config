maintainer       "sensu config"
maintainer_email "dn@365"
license          "All rights reserved"
description      "Installs/Configures sensu-config add aix and hpux add server"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.7"


# https://github.com/dn365/chef-base-config
depends "chef-base-config"

# https://github.com/dn365/chef-client
depends "chef-client"


%w[ ubuntu hpux aix centos redhat ].each do |os|
  supports os
end
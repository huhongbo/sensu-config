maintainer       "sensu config"
maintainer_email "dn@365"
license          "All rights reserved"
description      "Installs/Configures sensu-config add aix and hpux add server"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.6"

%w[ ubuntu hpux aix centos redhat ].each do |os|
  supports os
end

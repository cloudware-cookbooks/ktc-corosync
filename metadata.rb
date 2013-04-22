maintainer       "Robert Choi"
license          "Apache 2.0"
description      "Re-configures corosync to be used with clvm" 
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.0"

%w{ ubuntu fedora }.each do |os|
  supports os
end

depends "corosync"

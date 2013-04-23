#
# Cookbook Name:: ktc-corosync
# Recipe:: default
#
# Author: Robert Choi <taeilchoi1@gmail.com>
# Copyright 2013 by Robert Choi
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "corosync::default"

package "openais" do
  action :install
end

bindnetaddr = node['osops_networks']['management']

# Overwrite previous config
template "/etc/corosync/corosync.conf" do
  source "corosync.conf.erb"
  owner "root"
  group "root"
  mode 0600
  variables(:bindnetaddr => bindnetaddr)
end

# Overwrite previous config
template "/etc/default/corosync" do
  source "corosync.default.upstart.erb"
  owner "root"
  group "root"
  mode 0600
  variables(:enable_openais_service => node['corosync']['enable_openais_service'])
end

directory "/etc/cluster" do
  owner "root"
  group "root"
  mode 0755
  action :create
  notifies :create, "template[/etc/cluster/cluster.conf]", :immediately
  only_if {node['corosync']['enable_openais_service'] == 'yes'}
end

template "/etc/cluster/cluster.conf" do
  source "cluster.conf.erb"
  owner "root"
  group "root"
  mode 0600
  variables(
    :node1 => node['corosync']['cluster']['nodes'][0],
    :node2 => node['corosync']['cluster']['nodes'][1]
  )
  action :nothing
  only_if {node['corosync']['enable_openais_service'] == 'yes'}
end

# This block is not really necessary because chef would automatically backup thie file.
# However, it's good to have the backup file in the same directory. (Easier to find later.)
ruby_block "backup corosync init script" do
  block do
      original_pathname = "/etc/init.d/corosync"
      backup_pathname = original_pathname + ".old"
      FileUtils.cp(original_pathname, backup_pathname, :preserve => true)
  end
  action :create
  notifies :create, "cookbook_file[/etc/init.d/corosync]", :immediately
  not_if "test -f /etc/init.d/corosync.old"
end

cookbook_file "/etc/init.d/corosync" do
  source "corosync.init"
  owner "root"
  group "root"
  mode 0755
  action :nothing
  notifies :restart, "service[corosync]", :immediately
end

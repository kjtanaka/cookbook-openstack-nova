#
# Cookbook Name:: openstack-nova
# Recipe:: controller
# Author:: Koji Tanaka (<kj.tanaka@gmail.com>)
#
# Copyright 2013-2014, FutureGrid, Indiana University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

secrets = Chef::EncryptedDataBagItem.load("openstack", "secrets")

openstack_mysql_user = secrets['mysql_user']
openstack_mysql_password = secrets['mysql_password']
openstack_admin_token = secrets['admin_token']
openstack_admin_password = secrets['admin_password']
openstack_service_password = secrets['service_password']
openstack_mysql_host = node["openstack"]["admin_address"]
openstack_public_address = node["openstack"]["public_address"]
openstack_internal_address = node["openstack"]["internal_address"]
openstack_admin_address = node["openstack"]["admin_address"]
nova_db = node['openstack']['nova_db']
rabbit_user = secrets['rabbit_user']
rabbit_password = secrets['rabbit_password']
rabbit_virtual_host = secrets['rabbit_virtual_host']
openstack_public_interface = "eth1"
openstack_flat_interface = "eth0"
openstack_fixed_range = "192.168.33.0/24"

packages = %w[nova-api
              nova-cert
              nova-compute
              nova-compute-kvm
              nova-objectstore
              nova-network
              nova-scheduler
              nova-conductor
              nova-doc
              nova-console
              nova-consoleauth
              nova-novncproxy
              novnc
              openstack-dashboard]

packages.each do |pkg|
	package pkg do
	  action :install
  end
end

template "/etc/nova/nova.conf" do
  source "nova.conf.erb"
  mode "0644"
  owner "nova"
  group "nova"
  action :create
  variables(
    :openstack_admin_address => openstack_admin_address,
    :openstack_public_address => openstack_public_address,
    :openstack_service_password => openstack_service_password,
    :openstack_flat_interface => openstack_flat_interface,
    :openstack_public_interface => openstack_public_interface,
    :openstack_fixed_range => openstack_fixed_range,
    :openstack_mysql_password => openstack_mysql_password,
    :openstack_mysql_user => openstack_mysql_user,
    :openstack_mysql_host => openstack_mysql_host,
    :rabbit_user => rabbit_user,
    :rabbit_password => rabbit_password,
    :rabbit_virtual_host => rabbit_virtual_host,
    :nova_db => nova_db
  )
  notifies :run, "execute[nova_manage_db_sync]", :immediately
  notifies :restart, "service[nova-api]", :immediately
  notifies :restart, "service[nova-cert]", :immediately
  notifies :restart, "service[nova-consoleauth]", :immediately
  notifies :restart, "service[nova-scheduler]", :immediately
  notifies :restart, "service[nova-conductor]", :immediately
  notifies :restart, "service[nova-compute]", :immediately
  notifies :restart, "service[nova-network]", :immediately
  notifies :restart, "service[nova-novncproxy]", :immediately
  notifies :run, "execute[nova_manage_network_create]", :immediately
end

execute "nova_manage_db_sync" do
  user "nova"
  command "nova-manage db sync && touch /etc/nova/.db_synced_do_not_delete"
  creates "/etc/nova/.db_synced_do_not_delete"
  action :nothing
end

services = %w[nova-api nova-cert nova-compute nova-network nova-consoleauth nova-scheduler nova-conductor nova-novncproxy]

services.each do |svc|
  service svc do
    supports :restart => true
    restart_command "restart #{svc} || start #{svc}"
    action :nothing
  end
end

execute "nova_manage_network_create" do
  user "root"
  command "nova-manage network create --label private --num_networks=1 --fixed_range_v4=#{openstack_fixed_range} --bridge_interface=#{openstack_flat_interface} --network_size=256 --multi_host=T && touch /etc/nova/.network_create_do_not_delete"
  creates "/etc/nova/.network_create_do_not_delete"
  action :nothing
end

script "generate keypair" do
  interpreter "bash"
  user "root"
  cwd "/root"
  code <<-EOH
  test -d .ssh || mkdir .ssh && chmod 700 .ssh
  source admin_credential
  nova keypair-add key1 > .ssh/key1.pem
  chmod 600 .ssh/key1.pem
  echo StrictHostKeyChecking no >> .ssh/config
  echo UserKnownHostsFile=/dev/null >> .ssh/config
  EOH
  creates "/root/.ssh/key1.pem"
end

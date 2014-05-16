#
# Cookbook Name:: openstack-nova
# Recipe:: compute
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
              nova-compute
              nova-compute-kvm
              nova-network]

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
  notifies :stop, "service[nova-api]", :immediately
  notifies :stop, "service[nova-compute]", :immediately
  notifies :stop, "service[nova-network]", :immediately
  notifies :start, "service[nova-api]", :immediately
  notifies :start, "service[nova-compute]", :immediately
  notifies :start, "service[nova-network]", :immediately
end

services = %w[nova-api nova-compute nova-network]

services.each do |svc|
  service svc do
    supports :restart => true
    restart_command "restart #{svc}"
    start_command "start #{svc}"
    stop_command "stop #{svc}"
    action :nothing
  end
end


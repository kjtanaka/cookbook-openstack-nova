#
# Cookbook Name:: openstack-nova
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

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

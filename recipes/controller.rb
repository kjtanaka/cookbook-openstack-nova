#
# Cookbook Name:: openstack-nova
# Recipe:: default
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

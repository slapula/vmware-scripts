#!/usr/bin/env ruby
require 'rbvmomi'


test = RbVmomi::VIM.connect :host => 'localhost', :port => '14443', :user => '***REMOVED***', :password => '***REMOVED***', :insecure => true
rootFolder = test.serviceInstance.content.rootFolder
dc = rootFolder.childEntity.grep(RbVmomi::VIM::Datacenter).find { |x| x.name == "TEST" } or fail "datacenter not found"

def list_folders(df)
	vms = []
      	df.childEntity.each do |object|
        	if object.class.to_s == 'Folder'
          		vms += list_folders(object)
        	else
          		vms << object
        	end
      	end      	
	vms
end

vm = {}
rootFolder.childEntity.grep(RbVmomi::VIM::Datacenter).each do |dc|
	foldlist = list_folders(dc.vmFolder)
	foldlist.each do |vmlist|
		puts "#{vmlist.name} up for " + "#{vmlist.summary.quickStats.uptimeSeconds} seconds"
	end
	break if [:datastore]
end
vm

#dc = test.serviceInstance.find_datacenter("TEST") or fail "datacenter not found"
#host = dc.hostFolder.children.first.host.first
#folder1 = dc.hostFolder.children.name

host = dc.hostFolder.children.first.host.first
puts host.hardware.memorySize
puts host.hardware.cpuInfo.numCpuCores
puts host.summary.runtime.powerState
puts host.summary.quickStats.overallMemoryUsage
puts host.summary.quickStats.overallCpuUsage
puts host.summary.config.name

puts host.summary.config.product.fullName
puts host.summary.config.product.apiType
puts host.summary.config.product.apiVersion
puts host.summary.config.product.osType
puts host.summary.config.product.productLineId
puts host.summary.config.product.vendor
puts host.summary.config.product.version

#sleep 3



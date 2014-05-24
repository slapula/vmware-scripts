#!/usr/bin/env ruby
require 'rbvmomi'
require 'redis'

puts "Updating database...\n"

# -----------------------------------
# Essential Connections & Definitions
# -----------------------------------

test = RbVmomi::VIM.connect :host => 'localhost', :port => '14443', :user => '***REMOVED***', :password => '***REMOVED***', :insecure => true
rootFolder = test.serviceInstance.content.rootFolder

redis = Redis.new

# -------
# Methods
# -------

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

# ---------------------------------
# Collects data from Clusters
# ---------------------------------

rootFolder.childEntity.grep(RbVmomi::VIM::Datacenter).each do |dc|
	foldlist = list_folders(dc.hostFolder)
	foldlist.each do |hostlist|
		redis.select(1)
		redis.set "#{hostlist.name}", "#{hostlist.summary.overallStatus}", "#{vmlist.summary.numHosts}", "#{vmlist.summary.numEffectiveHosts}", "#{vmlist.summary.totalCpu}", "#{vmlist.summary.effectiveCpu}", "#{vmlist.summary.totalMemory}", "#{vmlist.summary.effectiveMemory}"
		
	end
end

# ---------------------------------
# Collects data from individual VMs 
# ---------------------------------

rootFolder.childEntity.grep(RbVmomi::VIM::Datacenter).each do |dc|
	foldlist = list_folders(dc.vmFolder)
	foldlist.each do |vmlist|
		redis.select(2)
		redis.set "#{vmlist.name}", "#{vmlist.summary.overallStatus}", "#{vmlist.summary.quickStats.uptimeSeconds}", "#{vmlist.summary.config.numCpu}", "#{vmlist.summary.quickStats.overallCpuUsage}", "#{vmlist.summary.config.memorySizeMB}", "#{vmlist.summary.quickStats.guestMemoryUsage}",
	end
end


# -----------------
# Close Connections
# -----------------

puts "Update complete\n"
redis.close
test.close

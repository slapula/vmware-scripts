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

def collectClusters(rf, db)
	rf.childEntity.grep(RbVmomi::VIM::Datacenter).each do |dc|
		foldlist = list_folders(dc.hostFolder)
		foldlist.each do |hostlist|
			db.select(1)
			db.hmset("#{hostlist.name}", "#{hostlist.summary.overallStatus}", "#{hostlist.summary.numHosts}", "#{hostlist.summary.numEffectiveHosts}", "#{hostlist.summary.totalCpu}", "#{hostlist.summary.effectiveCpu}", "#{hostlist.summary.totalMemory}", "#{hostlist.summary.effectiveMemory}")
		end
	end
end

collectClusters(rootFolder, redis)

# ---------------------------------
# Collects data from individual VMs 
# ---------------------------------

def collectVMs(rf, db)
	rf.childEntity.grep(RbVmomi::VIM::Datacenter).each do |dc|
		foldlist = list_folders(dc.vmFolder)
		foldlist.each do |vmlist|
			db.select(2)
			db.hmset("#{vmlist.name}", "#{vmlist.summary.overallStatus}", "#{vmlist.summary.quickStats.uptimeSeconds}", "#{vmlist.summary.config.numCpu}", "#{vmlist.summary.quickStats.overallCpuUsage}", "#{vmlist.summary.config.memorySizeMB}", "#{vmlist.summary.quickStats.guestMemoryUsage}")
		end
	end
end

#collectVMs(rootFolder, redis)

# -----------------
# Close Connections
# -----------------

puts "Update complete\n"
redis.quit
test.close

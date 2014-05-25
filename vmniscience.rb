#!/usr/bin/env ruby
require 'rbvmomi'
require 'redis'
require 'ruby-progressbar'

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
		progressbar = ProgressBar.create(:title => "Clusters", :format => '%t |%b>>%i| %p%% %a')
		progressbar.total = foldlist.count
		foldlist.each do |hostlist|
			db.select(1)
			db.hset("#{hostlist.name}", "Status", "#{hostlist.summary.overallStatus}")  
			db.hset("#{hostlist.name}", "NumberHosts", "#{hostlist.summary.numHosts}")
			db.hset("#{hostlist.name}", "EffectiveHosts", "#{hostlist.summary.numEffectiveHosts}") 
			db.hset("#{hostlist.name}", "CPUtotal", "#{hostlist.summary.totalCpu}")
			db.hset("#{hostlist.name}", "EffectiveCPU", "#{hostlist.summary.effectiveCpu}")
			db.hset("#{hostlist.name}", "MemTotal", "#{hostlist.summary.totalMemory}")
			db.hset("#{hostlist.name}", "EffectiveMem", "#{hostlist.summary.effectiveMemory}")
			progressbar.increment
		end
	end
end

#collectClusters(rootFolder, redis)

# ------------------------
# Collects data from Hosts
# ------------------------

def collectHosts(rf, db)
	rf.childEntity.grep(RbVmomi::VIM::Datacenter).each do |dc|
		count = 0
		dc.hostFolder.childEntity.each do |cluster|
			count += cluster.host.count
		end
		progressbar = ProgressBar.create(:title => "Hosts", :format => '%t |%b>>%i| %p%% %a')
		progressbar.total = count
		dc.hostFolder.childEntity.each do |cluster|
			cluster.host.each do |host|
				db.select(2)
				db.hset("#{host.name}", "Status", "#{host.summary.overallStatus}")
				db.hset("#{host.name}", "PowerStatus", "#{host.summary.runtime.powerState}")
				db.hset("#{host.name}", "Connection", "#{host.summary.runtime.connectionState}")
				db.hset("#{host.name}", "OverallCpu", "#{host.summary.quickStats.overallCpuUsage}")
				db.hset("#{host.name}", "OverallMem", "#{host.summary.quickStats.overallMemoryUsage}") 
				#db.hset("#{host.name}", "SystemSensor", "#{host.summary.runtime.healthSystemRuntime.systemHealthInfo.numericSensorInfo.name}")
				progressbar.increment
			end
		end
	end
end

collectHosts(rootFolder, redis)

# ---------------------------------
# Collects data from individual VMs 
# ---------------------------------

def collectVMs(rf, db)
	rf.childEntity.grep(RbVmomi::VIM::Datacenter).each do |dc|
		foldlist = list_folders(dc.vmFolder)
		progressbar = ProgressBar.create(:title => "VMs", :format => '%t |%b>>%i| %p%% %a')
		progressbar.total = foldlist.count
		foldlist.each do |vmlist|
			db.select(3)
			db.hset("#{vmlist.name}", "Status", "#{vmlist.summary.overallStatus}")
			db.hset("#{vmlist.name}", "Uptime", "#{vmlist.summary.quickStats.uptimeSeconds}")
			db.hset("#{vmlist.name}", "CPUusage", "#{vmlist.summary.quickStats.overallCpuUsage}")
			db.hset("#{vmlist.name}", "CPUnum", "#{vmlist.summary.config.numCpu}")
			db.hset("#{vmlist.name}", "MemUsage", "#{vmlist.summary.quickStats.guestMemoryUsage}")
			db.hset("#{vmlist.name}", "MemTotal", "#{vmlist.summary.config.memorySizeMB}")
			progressbar.increment
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

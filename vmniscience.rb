#!/usr/bin/env ruby
require 'rbvmomi'
require 'redis'
require 'ruby-progressbar'

# --------------------------------------
# Vmniscience is Omniscience for VMware!
# --------------------------------------

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

def counter(dc, folder)
	count = 0
	if folder == "h"	
		dc.hostFolder.childEntity.each do |cluster|
			count += cluster.host.count
		end
	elsif folder == "v"
		dc.vmFolder.childEntity.each do |x|
			count += x.childEntity.count 
		end
	elsif folder == "c"
		count += dc.hostFolder.childEntity.count
	end
	count
end	

# ---------------------------------
# Collects data from Clusters
# ---------------------------------

def collectClusters(rf, db)
	rf.childEntity.grep(RbVmomi::VIM::Datacenter).each do |dc|
		progressbar = ProgressBar.create(:title => "Clusters", :format => '%t |%b>>%i| %p%% %a')
		progressbar.total = counter(dc, "c")
		dc.hostFolder.childEntity.each do |cluster|
			db.select(1)
			db.hset("#{cluster.name}", "Status", "#{cluster.summary.overallStatus}")  
			db.hset("#{cluster.name}", "NumberHosts", "#{cluster.summary.numHosts}")
			db.hset("#{cluster.name}", "EffectiveHosts", "#{cluster.summary.numEffectiveHosts}") 
			db.hset("#{cluster.name}", "CPUtotal", "#{cluster.summary.totalCpu}")
			db.hset("#{cluster.name}", "EffectiveCPU", "#{cluster.summary.effectiveCpu}")
			db.hset("#{cluster.name}", "MemTotal", "#{cluster.summary.totalMemory}")
			db.hset("#{cluster.name}", "EffectiveMem", "#{cluster.summary.effectiveMemory}")
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
		progressbar = ProgressBar.create(:title => "Hosts", :format => '%t |%b>>%i| %p%% %a')
		progressbar.total = counter(dc, "h")
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

#collectHosts(rootFolder, redis)

# ---------------------------------
# Collects data from individual VMs 
# ---------------------------------

def collectVMs(rf, db)
	rf.childEntity.grep(RbVmomi::VIM::Datacenter).each do |dc|
		progressbar = ProgressBar.create(:title => "VMs", :format => '%t |%b>>%i| %p%% %a')
		progressbar.total = counter(dc, "v")
		dc.vmFolder.childEntity.each do |folder|
			folder.childEntity.each do |vmlist|
				next if vmlist.class.to_s == "Folder"
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
end

collectVMs(rootFolder, redis)

# -----------------
# Close Connections
# -----------------

puts "Update complete\n"
redis.quit
test.close

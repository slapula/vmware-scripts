#!/usr/bin/env ruby
require 'rbvmomi'
require 'redis'

# --------------------------------------
# Vmniscience is Omniscience for VMware!
# --------------------------------------

puts "Which VM would you like to get data from? "
$single_vm = gets.chomp

puts "Updating database...\n"

# -----------------------------------
# Essential Connections & Definitions
# -----------------------------------

test = RbVmomi::VIM.connect :host => 'localhost', :port => '14443', :user => '***REMOVED***', :password => '***REMOVED***', :insecure => true
rootFolder = test.serviceInstance.content.rootFolder

redis = Redis.new

# ---------------------------------
# Collects data from individual VMs 
# ---------------------------------

def collectVMs(rf, db)
	rf.childEntity.grep(RbVmomi::VIM::Datacenter).each do |dc|
		dc.vmFolder.childEntity.each do |folder|
			if folder.childEntity.find { |x| x.name == "#{$single_vm}" }
				y = folder.childEntity.find { |x| x.name == "#{$single_vm}" }
				db.select(3)
				db.hset("#{y.name}", "Status", "#{y.summary.overallStatus}")
				db.hset("#{y.name}", "Uptime", "#{y.summary.quickStats.uptimeSeconds}")
				db.hset("#{y.name}", "CPUusage", "#{y.summary.quickStats.overallCpuUsage}")
				db.hset("#{y.name}", "CPUnum", "#{y.summary.config.numCpu}")
				db.hset("#{y.name}", "MemUsage", "#{y.summary.quickStats.guestMemoryUsage}")
				db.hset("#{y.name}", "MemTotal", "#{y.summary.config.memorySizeMB}")
				break
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

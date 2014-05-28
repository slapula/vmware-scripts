#!/usr/bin/env ruby
require 'rbvmomi'
require 'redis'
require 'ruby-progressbar'

# --------------------------------------
# Vmniscience is Omniscience for VMware!
# --------------------------------------

puts "Which VM folder would you like to get data from? "
single_folder = gets

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
		progressbar = ProgressBar.create(:title => "#{single_folder}", :format => '%t |%b>>%i| %p%% %a')
		count = 0
		dc.vmFolder.childEntity.each do |x|
			count += x.childEntity.count 
		end
		progressbar.total = count
		dc.vmFolder.childEntity.each do { |folder| folder.name == "#{single_folder}" }
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

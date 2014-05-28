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

# ------------------------
# Collects data from Hosts
# ------------------------

def collectHosts(rf, db)
	rf.childEntity.grep(RbVmomi::VIM::Datacenter).each do |dc|
		#count = 0
		#dc.hostFolder.childEntity.each do |cluster|
		#	count += cluster.host.count
		#end
		#progressbar = ProgressBar.create(:title => "Hosts", :format => '%t |%b>>%i| %p%% %a')
		#progressbar.total = count
		dc.hostFolder.childEntity.each do |cluster|
			cluster.host.each do |host|
				#db.select(2)
				#db.hset("#{host.name}", "Status", "#{host.summary.overallStatus}")
				#db.hset("#{host.name}", "PowerStatus", "#{host.summary.runtime.powerState}")
				#db.hset("#{host.name}", "Connection", "#{host.summary.runtime.connectionState}")
				#db.hset("#{host.name}", "OverallCpu", "#{host.summary.quickStats.overallCpuUsage}")
				#db.hset("#{host.name}", "OverallMem", "#{host.summary.quickStats.overallMemoryUsage}") 
				#host.runtime.healthSystemRuntime.systemHealthInfo.numericSensorInfo.each do |sensor|
				#	puts "#{host.name}: #{sensor.name} #{sensor.sensorType} #{sensor.healthState.key}" 
				#end
				host.runtime.healthSystemRuntime.hardwareStatusInfo.cpuStatusInfo.each do |sensor|
					puts "#{host.name}: #{sensor.name} #{sensor.status.key}" 
				end
				host.runtime.healthSystemRuntime.hardwareStatusInfo.memoryStatusInfo.each do |sensor|
					puts "#{host.name}: #{sensor.name} #{sensor.status.key}" 
				end
				#progressbar.increment
			end
		end
	end
end

collectHosts(rootFolder, redis)

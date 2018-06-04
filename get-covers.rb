#!/usr/bin/env ruby

# By Michael Chaney, Michael Chaney Consulting Corporation
# Copyright 2006 Michael Chaney Consulting Corporation
# All Rights Reserved

SCRIPT_PATH = File.expand_path(File.dirname(__FILE__))

require 'getoptlong'
require 'pp'
require 'net/http'

require "#{SCRIPT_PATH}/ms.rb"
include MS
require "#{SCRIPT_PATH}/tracks.rb"
include MSTracks

@debug = @verbose = false

opts = GetoptLong.new(
	[ '--debug',    '-d',      GetoptLong::NO_ARGUMENT],
   [ '--verbose',  '-v',      GetoptLong::NO_ARGUMENT]
)

opts.each do |opt, arg|
	@debug = true if opt == '--debug'
	@verbose = true if opt == '--verbose'
end

unless ARGV[0]
  STDERR.print "Usage: #{$0} directory\n"
  exit 1
end

directory = ARGV[0]

STDERR.puts "Getting track list for cds" if @debug

tracks = load_tracks

formats = %w{ th.jpg jpg }

# Get a list of all cds from the tracks versions
cds = {}
tracks.each do |t|
  if t
    t['versions'].each do |tv|
		cds[tv['cd_id']] = tv['cd'] unless cds[tv['cd_id']]
    end
  end
end

STDERR.puts "Checking covers" if @debug

# cover files are named cd_key.format
Dir.chdir(directory)
cds.each_key do |cd_id|
	cd = cds[cd_id]
	formats.each do |fmt|
		cover_file = "#{cd['cd_key']}.#{fmt}"
		unless File.exist?(cover_file)
			Net::HTTP.start('www.mastersource.com', 80) do |http|
				req = Net::HTTP::Get.new("/images/covers/#{cover_file}")
				resp = http.request(req)
				if resp.code == '200'
					File.open(cover_file, 'w') do |f|
						f.write(resp.body)
					end
					STDERR.print "Got #{cover_file}\n" if @verbose
				else
					warn "Cannot get #{cover_file}, status #{resp.code}."
				end
			end
		end
	end
end

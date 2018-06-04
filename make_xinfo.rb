#!/usr/bin/env ruby

# By Michael Chaney, Michael Chaney Consulting Corporation
# Copyright 2006 Michael Chaney Consulting Corporation
# All Rights Reserved

require 'yaml'
require 'getoptlong'
require 'pp'

SCRIPT_PATH = File.expand_path(File.dirname(__FILE__))
require "#{SCRIPT_PATH}/ms.rb"
include MS
require "#{SCRIPT_PATH}/tracks.rb"
include MSTracks

@file_list = @debug = @verbose = false

opts = GetoptLong.new(
	[ '--debug',    '-d',      GetoptLong::NO_ARGUMENT],
   [ '--verbose',  '-v',      GetoptLong::NO_ARGUMENT],
   [ '--files',    '-f',      GetoptLong::REQUIRED_ARGUMENT]
)

opts.each do |opt, arg|
	@debug = true if opt == '--debug'
	@verbose = true if opt == '--verbose'
	@file_list = arg if opt == '--files'
end

unless @file_list
  STDERR.print "Usage: #{$0} --files file_list.yaml\n"
  exit 1
end

tracks = load_tracks
files = YAML.load_file(@file_list)

# The fields that must go in the xinfo.js file
#Category	library_id	track_id	Title	Artist	Genre	Subgenres	Lyrical Themes	Lead	Tempo

$\ = nil

print "xinfo=[\n"

first = true

tracks.each do |t|
	print ",\n" unless first
   first = false
	if t
		print "\t{\n"
		printf "\t\tid: %d,\n", t['id']
		printf "\t\tcd_id: %d,\n", t['versions'][0]['cd_id']
		printf "\t\tseconds: %d,\n", t['versions'][0]['seconds']
		printf "\t\ttitle: \"%s\",\n", t['title'].gsub(/"/, '\\\"')
		printf "\t\tdescription: \"%s\",\n", t['description'].gsub(/"/, '\\\"').gsub(/\r?\n/, ' ')
      vocal_file_version = t['versions'].detect { |tv| tv && tv['version']['has_vocal']=='t' }
      inst_file_version = t['versions'].detect { |tv| tv && tv['version']['has_vocal']!='t' }
      printf "\t\tvocal_file_path: \"%s\"", files[t['id']][vocal_file_version['track_version_number'].to_i]['path'].gsub(/"/, '\\\"') if vocal_file_version
      printf "," if vocal_file_version && inst_file_version
      print "\n"
      printf "\t\tinst_file_path: \"%s\"\n", files[t['id']][inst_file_version['track_version_number'].to_i]['path'].gsub(/"/, '\\\"') if inst_file_version
		print "\t}"
	end
end

print "\n];\n"

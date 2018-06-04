#!/usr/bin/env ruby

# By Michael Chaney, Michael Chaney Consulting Corporation
# Copyright 2006 Michael Chaney Consulting Corporation
# All Rights Reserved

# Make sure that all track/versions/formats in the input exist in the
# "source-files.yaml" structure (i.e. they're on the source drive).
# We'll exit with "1" if not, after barfing some errors, so that the
# user can fix this problem.

SCRIPT_PATH = File.expand_path(File.dirname(__FILE__))

require 'yaml'

require 'getoptlong'
require 'pp'

require "#{SCRIPT_PATH}/ms.rb"
include MS

require "#{SCRIPT_PATH}/tracks.rb"
include MSTracks

@file_list = @track_file = @debug = @verbose = false

opts = GetoptLong.new(
	[ '--debug',    '-d',      GetoptLong::NO_ARGUMENT],
   [ '--verbose',  '-v',      GetoptLong::NO_ARGUMENT],
   [ '--tracks',   '-t',      GetoptLong::REQUIRED_ARGUMENT],
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

error_found = false

tracks.each do |t|
  if t
    t['versions'].each do |tv|
      next unless tv['has_file']=='t'
      unless files[t['id']] && files[t['id']][tv['track_version_number'].to_i] && files[t['id']] && files[t['id']][tv['track_version_number'].to_i]['path']
        unless error_found
          error_found = true
          STDERR.print "You have missing audio files for the following tracks:\n"
        end
        STDERR.printf "   %s\n", tv['file_path']
      end
    end
  end
end

if error_found
  exit 1
end

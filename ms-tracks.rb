#!/usr/bin/env ruby

# By Michael Chaney, Michael Chaney Consulting Corporation
# Copyright 2006 Michael Chaney Consulting Corporation
# All Rights Reserved
#
# Gets information for all tracks, saves to yaml file for later use.

SCRIPT_PATH = File.expand_path(File.dirname(__FILE__))

require 'rubygems'
require "#{SCRIPT_PATH}/ms.rb"
require 'getoptlong'
require 'pp'

include MS

require "#{SCRIPT_PATH}/tracks.rb"
include MSTracks

@verbose = @debug = false

opts = GetoptLong.new(
  [ '--debug',    '-d',      GetoptLong::NO_ARGUMENT],
  [ '--verbose',  '-v',      GetoptLong::NO_ARGUMENT]
)

opts.each do |opt, arg|
  @debug = true if opt == '--debug'
  @verbose = true if opt == '--verbose'
end

refresh_data

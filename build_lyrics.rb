#!/usr/bin/env ruby

# By Michael Chaney, Michael Chaney Consulting Corporation
# Copyright 2006 Michael Chaney Consulting Corporation
# All Rights Reserved

# The directory tree will be build/lyrics/xy/zzxy.txt
# The file will simply contain the lyrics for the track.

SCRIPT_PATH = File.expand_path(File.dirname(__FILE__))
require "#{SCRIPT_PATH}/ms.rb"
include MS
require "#{SCRIPT_PATH}/tracks.rb"
include MSTracks

tracks = load_tracks

$\ = nil

Dir.mkdir('build') unless File.exist?('build')
Dir.mkdir('build/lyrics') unless File.exist?('build/lyrics')
0.step(99) do |n|
  dir=sprintf('build/lyrics/%02d', n)
  Dir.mkdir(dir) unless File.exist?(dir)
end

tracks.each do |t|
  if t && t['lyrics'] && !t['lyrics'].empty?
    File.open(sprintf('build/lyrics/%02d/%d.txt',t['id']%100,t['id']),'w') do |f|
      f.print t['lyrics']
    end
  end
end

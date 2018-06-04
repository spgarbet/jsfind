#!/usr/bin/env ruby
#
# By Michael Chaney, Michael Chaney Consulting Corporation
# Copyright 2008, Michael Chaney Consulting Corporation, All Rights Reserved
#
# This will parse the msfiles.txt directory listing (just dir/w/b/s for now)
# into a prettier format (key \t format \t path) which can more easily be
# read/parsed by other programs.  Filename styles:
#
# celebri-themes - events (EV), fashion (F), relationships (R), and bling things (BT)
# Includes cd number (i.e. "EV2") and track number
# CELEBTHEMEEV2_01 It'sPremie.wav
# CELEBTHEMEF2_01 LookingHot.wav
# CELEBTHEMER1_17 InAndOutOfL.wav
# CELEBTHEMEBT2_01 BigFatRide.wav
#
# topshelf - includes a Volume #, CD # and track number
# TSV2_CD1_06 DriveHappy.wav
#
# holiday music - includes volume (i.e. "3A" or "2") and track number
# MSHM_3A_01 ShootingStar.wav
# MSHM_2_01 JesusWasBornOnChr.wav
#
# Trailer and promo music - volume and track number
# MSTPM_2_01 VirtualVelocity.wav
#
# MasterSource - volume (numeric), cd number and track number
# MSV01CD04_01 InTooDeep.wav

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

# of course, tracks is keyed on the track id
tracks = load_tracks

@collections = []

@keyed_tracks = {}
tracks.each do |t|
  next unless t
  t['versions'].each do |tv|
    next unless tv
    collection = tv['cd']['volume']['collection']
    @collections[collection['id'].to_i] ||= collection
    tv['track'] = t
    track_key = normalize_track_key(tv['track_key'], collection['cd_key_regexp'], collection['cd_key_format'])
    if track_key
      @keyed_tracks[track_key] = tv
    else
      STDERR.printf "Cannot normalize track key \"%s\"\n", tv['track_key']
    end
  end
end

# @msfiles[track_id][track_version_number][format] = file
# @msfiles[track_id][track_version_number]['path'] = generic path
@msfiles = Hash.new

while gets
  found = true
  path = fname = ext = format = nil
  if $_ =~ /^[A-Z]:\\(.+)\\(.*?)\.(wav|aif|mp3)/i
    path, fname, ext = $1, $2, $3
  elsif $_ =~ /^(.+)\/(.*?)\.(wav|aif|mp3)/i
    path, fname, ext = $1, $2, $3
  end
  if path && path !~ /trashes/i && fname !~ /^\._/
    collection = @collections.detect { |c| c && fname =~ /^(#{c['cd_key_regexp']}_(\d+))( |$)/i }
    if collection
      key = $1
      official_key = normalize_track_key(key, collection['cd_key_regexp'], collection['cd_key_format'])
      path.gsub!(/\\/, '/')
      if path =~ /Wav Files_44\/+(.*)/
        format = '44.1K Wav'
      elsif path =~ /Aif Files_48\/+(.*)/
        format = '48K AIFF'
      elsif path =~ /MP3_128k\/+(.*)/
        format = '128K MP3'
      elsif path =~ /MP3 192k\/+(.*)/
        format = '192K MP3'
      else
        STDERR.printf "Confusing path:\n\"%s\"\n", path
      end
      uniq = $1
      if uniq
        tv = @keyed_tracks[key]
        unless tv
          # second try, parsing filename
          tv = @keyed_tracks[official_key]
        end
        if tv
          track_id = tv['track']['id'].to_i
          tvn = tv['track_version_number'].to_i
          @msfiles[track_id] ||= []
          @msfiles[track_id][tvn] ||= {}
          @msfiles[track_id][tvn][format] = "#{path}/#{fname}.#{ext}"
          @msfiles[track_id][tvn]['path'] = "#{uniq}/#{fname}"
          #printf "%s\t%s\t%s/%s.%s\t%s/%s\n", $key, $format, $path, $fname, $ext, $uniq, $fname;
        else
          STDERR.printf "Track not found: %s\n", fname
        end
      end
    else
      STDERR.printf "Unknown filename:\n%s (%s)\n", $_, fname
    end
  elsif $_ !~ /^\s*$/ && fname !~ /^\._/
    STDERR.printf "Unknown filename:\n%s\n", $_
  end
end

STDERR.print "Output yaml...\n" if @debug

puts YAML.dump(@msfiles)

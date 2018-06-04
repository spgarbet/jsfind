#!/usr/bin/env ruby

# By Michael Chaney, Michael Chaney Consulting Corporation
# Copyright 2006 Michael Chaney Consulting Corporation
# All Rights Reserved

# The directory tree will be xinfo/xy/zzxy.js
# Basically, the last two digits of the track id will be the directory,
# so it should fill up quite evenly.

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

# Determine the start of the prior quarter, use that to determine if
# this is a new track.
date = Date.today
start_of_prior_quarter = Date.new(date.year, (date.month-1)/3*3+1, 1) << 3

$\ = nil

Dir.mkdir('xinfo') unless File.exist?('xinfo')
0.step(99) do |n|
  dir=sprintf('xinfo/%02d', n)
  Dir.mkdir(dir) unless File.exist?(dir)
end

tracks.each do |t|
  if t
    File.open(sprintf('xinfo/%02d/%d.js',t['id']%100,t['id']),'w') do |f|
      f.printf "xinfo[%d]={\n", t['id']
      f.printf "\tid: %d,\n", t['id']
		f.printf "\tcd_id: %d,\n", t['versions'][0]['cd_id']
		f.printf "\tseconds: %d,\n", t['versions'][0]['seconds']
      f.printf "\ttitle: \"%s\",\n", t['title'].gsub(/\r?\n/," ").gsub(/"/, '\\\"')
      f.printf "\tdescription: \"%s\",\n", t['description'].gsub(/\r?\n/,"\\n").gsub(/"/, '\\\"')
      vocal_file_version = t['versions'].detect { |tv| tv && tv['version']['has_vocal']=='t' }
      inst_file_version = t['versions'].detect { |tv| tv && tv['version']['has_vocal']!='t' }
      f.printf "\tvocal_file_path: \"%s\",\n", files[t['id']][vocal_file_version['track_version_number'].to_i]['path'].gsub(/"/, '\\\"') if vocal_file_version
      f.printf "\tinst_file_path: \"%s\",\n", files[t['id']][inst_file_version['track_version_number'].to_i]['path'].gsub(/"/, '\\\"') if inst_file_version
      f.printf "\tgenre_ids: [%s],\n", t['genres'].collect { |g| g['id'] }.join(',')
      f.printf "\tsub_genre_ids: [%s],\n", t['sub_genres'].collect { |sg| sg['id'] }.join(',')
      f.printf "\tgenres_and_sub_genre_ids: [%s],\n", t['genres_and_sub_genres'].collect { |gasg| gasg['id'] }.join(',')
      f.printf "\tlyrical_theme_ids: [%s],\n", t['lyrical_themes'].collect { |lt| lt['id'] }.join(',')
      f.printf "\tlead_id: %d,\n", t['lead']['id'] if t['lead']
      f.printf "\ttempo_id: %d,\n", t['tempo']['id'] if t['tempo']

      f.printf "\tera_id: %d,\n", t['era']['id'] if t['era']
      f.printf "\tis_arrangement: %s,\n", t['is_arrangement']
      f.printf "\tstyle_alike: \"%s\",\n", t['style_alike'].gsub(/\r?\n/,"\\n").gsub(/"/, '\\\"')
      f.printf "\tmood_ids: [%s],\n", t['moods'].collect { |m| m['id'] }.join(',')
      f.printf "\tlead_ids: [%s],\n", t['leads'].collect { |l| l['id'] }.join(',')
      f.printf "\tinstrument_ids: [%s],\n", t['instruments'].collect { |i| i['id'] }.join(',')
      f.printf "\tperformer_ids: [%s],\n", t['performers'].collect { |p| p['id'] }.join(',')
      f.printf "\torchestration_id: %d,\n", t['orchestration']['id'] if t['orchestration']
      f.printf "\tlanguage_id: %d,\n", t['language']['id'] if t['language']
      f.printf "\tkey_id: %d,\n", t['key']['id'] if t['key']
      f.printf "\tbpm_range_id: %d,\n", t['bpm_range_id'] if t['bpm_range_id']
      #versions & filepaths
      f.print "\tversions: {\n"
      first_version = true
      t['versions'].each do |tv|
        unless first_version
          f.print ",\n"
        else
          first_version=false
        end
        f.printf "\t\t%d: { cd_id: %d, cd_track_number: %d, version_id: %d, cut_id: %d, pretty_version_name: \"%s\", seconds: %d,\n\t\t\tdescription: \"%s\",\n\t\t\tfile: \"%s\"\n\t\t}",tv['track_version_number'], tv['cd_id'], tv['cd_track_number'], tv['version_id'], tv['cut_id'], tv['pretty_version_name'], tv['seconds'], tv['description'].gsub(/"/,'\\\"'), files[t['id']][tv['track_version_number'].to_i]['path']
      end
      f.print "\n\t},\n"
      #composers
      f.printf "\tcomposers: {\n%s\n\t},\n", t['composers'].collect { |c| sprintf("\t\t%d: { percentage: %d }", c['id'], c['percentage']) }.join(",\n");
      #publishers
      f.printf "\tpublishers: {\n%s\n\t},\n", t['publishers'].collect { |p| sprintf("\t\t%d: { percentage: %s }", p['id'], p['percentage']) }.join(",\n");
      #registration codes
      f.printf "\tregistration_codes: [\n%s\n\t],\n", t['registration_codes'].collect { |rc| sprintf("\t\t{ registration_type_id: %d, code: \"%s\" }", rc['registration_type_id'], rc['code']) }.join(",\n");
      #includes_instrumental
      if t['versions'].any? { |tv| tv['version']['has_vocal'] != 't' }
        f.print "\thas_instrumental: true,\n"
      else
        f.print "\thas_instrumental: false,\n"
      end
      if t['versions'].any? { |tv| tv['version']['has_vocal'] == 't' }
        f.print "\thas_vocal: true,\n"
      else
        f.print "\thas_vocal: false,\n"
      end
      #lyrics
      if !t['lyrics'] || t['lyrics'].empty?
        f.print "\tlyrics: false,\n"
      else
        f.printf "\tlyrics: \"%s\",\n", t['lyrics'].gsub(/\r?\n/,"\\n").gsub(/"/,'\\"')
      end

      f.printf "\t'new': %s,\n", DateTime.parse(t['created_at']) >= start_of_prior_quarter ? 'true' : 'false'

      f.print "\tfull: true\n"
      f.print "}\n"
    end
  end
end

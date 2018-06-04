#!/usr/bin/env ruby

# By Michael Chaney, Michael Chaney Consulting Corporation
# Copyright 2006 Michael Chaney Consulting Corporation
# All Rights Reserved

# The directory tree will be build/main/xy/zzxy.txt
# Basically, the last two digits of the track id will be the directory,
# so it should fill up quite evenly.

SCRIPT_PATH = File.expand_path(File.dirname(__FILE__))
require "#{SCRIPT_PATH}/ms.rb"
include MS
require "#{SCRIPT_PATH}/tracks.rb"
include MSTracks

tracks = load_tracks

Dir.mkdir('build') unless File.exist?('build')
Dir.mkdir('build/main') unless File.exist?('build/main')
0.step(99) do |n|
  dir=sprintf('build/main/%02d', n)
  Dir.mkdir(dir) unless File.exist?(dir)
end

$\ = "\n"

def only_words(str)
	str.gsub(/(\w)'(\w)/,'\1\2').gsub(/[^\w_\- ]+/,' ')
end

# Determine the start of the prior quarter, use that to determine if
# this is a new track.
date = Date.today
start_of_quarter = Date.new(date.year, (date.month-1)/3*3+1, 1)
if start_of_quarter.month==1
  start_of_prior_quarter = Date.new(start_of_quarter.year-1, 10, 1)
else
  start_of_prior_quarter = Date.new(start_of_quarter.year, start_of_quarter.month-3, 1)
end

has_instrumental=''
tracks.each do |t|
  if t && t['versions'].any? { |tv| tv['version']['has_vocal'] != 't' }
      has_instrumental="has_instrumental";
  end
end

tracks.each do |t|
  if t
    File.open(sprintf('build/main/%02d/%d.txt',t['id']%100,t['id']),'w') do |f|
      f.printf "id:%d\n", t['id']
      f.print only_words(t['title'])
		t['genres'].each { |g| f.printf "genre_id:%d\n", g['id'] }
		t['genres'].each { |g| f.print only_words(g['name']) }
		t['sub_genres'].each { |g| f.printf "sub_genre_id:%d\n", g['id'] }
		t['sub_genres'].each { |g| f.print only_words(g['name']) }
		t['sub_genres'].each { |sg| f.printf "genre_id:%d\n", sg['genre_id'] }
		t['sub_genres'].each { |sg| f.print only_words(sg['genre']['name']) }
		t['genres_and_sub_genres'].each { |gasg| f.printf "genres_and_sub_genres_id:%d\n", gasg['id'] }
		t['lyrical_themes'].each { |lt| f.printf "lyrical_theme_id:%d\n", lt['id'] }
		t['lyrical_themes'].each { |lt| f.print only_words(lt['theme']) }
		t['moods'].each { |m| f.printf "mood_id:%d\n", m['id'] }
		t['moods'].each { |m| f.print only_words(m['name']) }
		t['instruments'].each { |m| f.printf "instrument_id:%d\n", m['id'] }
		t['instruments'].each { |m| f.print only_words(m['name']) }
		t['leads'].each { |m| f.printf "lead_id:%d\n", m['id'] }
		t['leads'].each { |m| f.print only_words(m['name']) }
		t['performers'].each { |m| f.printf "performer_id:%d\n", m['id'] }
		t['performers'].each { |m| f.print only_words(m['name']) }

      f.printf "bpm_range_id:%d\n", t['bpm_range_id'] if t['bpm_range_id']

      f.printf "tempo_id:%d\n", t['tempo']['id'] if t['tempo']
      f.print only_words(t['tempo']['name']) if t['tempo']

      f.printf "key_id:%d\n", t['key']['id'] if t['key']
      f.print only_words(t['key']['name']) if t['key']

      f.printf "language_id:%d\n", t['language']['id'] if t['language']
      f.print only_words(t['language']['name']) if t['language']

      f.printf "era_id:%d\n", t['era']['id'] if t['era']
      f.print only_words(t['era']['name']) if t['era']
      f.printf "is_arrangement:%s\n", t['is_arrangement'] ? 1 : 0
      f.print only_words(t['description'])
      f.print only_words(t['style_alike'])
      f.printf "orchestration_id:%d\n", t['orchestration']['id'] if t['orchestration']
      f.print only_words(t['orchestration']['name']) if t['orchestration']

      f.printf "cds_and_collections_id:%d\n", t['cds_and_collections_id']

      #versions
      t['versions'].each { |v| f.printf "version_id:%d\n", v['version_id'] }
      t['versions'].each { |v| f.printf "cut_id:%d\n", v['cut_id'] }
      t['versions'].each { |v| f.printf "cd_id:%d\n", v['cd_id'] }
      t['versions'].each { |v| f.printf "%s\n", v['cd']['cd_key'] }
      t['versions'].each { |v| f.printf "%s\n", v['cd']['cd_name'] }
      t['versions'].each { |v| f.printf "volume_id:%d\n", v['cd']['volume_id'] }
      t['versions'].each { |v| f.printf "collection_id:%d\n", v['cd']['volume']['collection_id'] }
      t['versions'].each { |v| f.printf "cds_and_collections_id:%d\n", v['cds_and_collections_id'] }
      t['versions'].each { |v| v['cd']['subsets'].each { |s| f.printf "subset_id:%d\n", s['id'] } if v['cd']['subsets'] }
      t['versions'].each { |v| f.printf "%s\n", v['cd']['volume']['collection']['collection_name'] }
      t['versions'].each { |v| f.print only_words(v['pretty_version_name']) unless v['pretty_version_name'] == 'full' }
      #composers
		t['composers'].each { |c| f.printf "composer_id:%d\n", c['id'] }
		t['composers'].each { |c| f.print only_words(c['contact_name']) }
      #publishers
		t['publishers'].each { |p| f.printf "publisher_id:%d\n", p['id'] }
		t['publishers'].each { |p| f.print only_words(p['name']) }
      #registration codes
      t['registration_codes'].each { |rc| f.print rc['code'] }
      f.print "has_version:instrumental\n" if t['versions'].any? { |tv| tv['version']['has_vocal'] != 't' }
      f.printf("has_instrumental:%d\n", (t['versions'].any? { |tv| tv['version']['has_vocal'] != 't' } ? 1 : 0))
      f.print "has_version:vocal\n" if t['versions'].any? { |tv| tv['version']['has_vocal'] == 't' }
      f.printf("has_vocal:%d\n", (t['versions'].any? { |tv| tv['version']['has_vocal'] == 't' } ? 1 : 0))

      f.print "new_track\n" if DateTime.parse(t['created_at']) >= start_of_prior_quarter

    end
  end
end

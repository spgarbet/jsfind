#!/usr/bin/env ruby

# By Michael Chaney, Michael Chaney Consulting Corporation
# Copyright 2006 Michael Chaney Consulting Corporation
# All Rights Reserved

SCRIPT_PATH = File.expand_path(File.dirname(__FILE__))
require "#{SCRIPT_PATH}/ms.rb"
include MS
require "#{SCRIPT_PATH}/tracks.rb"
include MSTracks

tracks = load_tracks

# This outputs an array, where the key is the track id and the value is
# the sort order.

$\ = nil

# Need to sort by "title", "cd_name + track #", "track_key + track #", "time"
print "var xsort=new Object;\n"

# track default sort (collection, volume number desc, track title)
sorted_track_ids = tracks.sort_by { |t| t ? [t['versions'][0]['cd']['volume']['collection']['sort_order'].to_i, 1000-t['versions'][0]['cd']['volume']['volume_number'].to_i, t['title'] ] : [0, 0, ''] }.collect { |t| t ? t['id'] : 0 }
sorted_track_ids.each_index { |i| tracks[sorted_track_ids[i]]['sort_order']=i if tracks[sorted_track_ids[i]] }

print "xsort['default']=[" + tracks.collect { |t| t ? t['sort_order'] : ''}.join(',') + "];\n";

# track title sort
sorted_track_ids = tracks.sort { |a,b| (a && b) ? (a['title']<=>b['title']) : ( a ? 1 : 0 ) }.collect { |t| t ? t['id'] : 0 }
sorted_track_ids.each_index { |i| tracks[sorted_track_ids[i]]['sort_order']=i if tracks[sorted_track_ids[i]] }

print "xsort['title']=[" + tracks.collect { |t| t ? t['sort_order'] : ''}.join(',') + "];\n";

# cd_name + track # sort
sorted_track_ids = tracks.sort_by { |t| t ? [t['versions'][0]['cd']['cd_name'], t['versions'].min { |a,b| a['cd_track_number'].to_i-b['cd_track_number'].to_i}['cd_track_number'].to_i] : ['',0] }.collect { |t| t ? t['id'] : 0 }
sorted_track_ids.each_index { |i| tracks[sorted_track_ids[i]]['sort_order']=i if tracks[sorted_track_ids[i]] }

print "xsort['cd_name']=[" + tracks.collect { |t| t ? t['sort_order'] : ''}.join(',') + "];\n";

# track_key + track # sort
sorted_track_ids = tracks.sort { |a,b| (a && b) ? (a['versions'][0]['track_key']<=>b['versions'][0]['track_key']) : ( a ? 1 : 0 ) }.collect { |t| t ? t['id'] : 0 }
sorted_track_ids.each_index { |i| tracks[sorted_track_ids[i]]['sort_order']=i if tracks[sorted_track_ids[i]] }

print "xsort['track_key']=[" + tracks.collect { |t| t ? t['sort_order'] : ''}.join(',') + "];\n";

# time + title
sorted_track_ids = tracks.sort_by { |t| t ? [(t['versions'].max { |a,b| a['seconds'].to_i-b['seconds'].to_i }['seconds'].to_i), t['title']] : [ 0, '' ] }.collect { |t| t ? t['id'] : 0 }
sorted_track_ids.each_index { |i| tracks[sorted_track_ids[i]]['sort_order']=i if tracks[sorted_track_ids[i]] }

print "xsort['time']=[" + tracks.collect { |t| t ? t['sort_order'] : ''}.join(',') + "];\n";


# Sorting for cds
cds = []
tracks.each do |t|
  if t
    t['versions'].each { |v| cds[v['cd_id'].to_i] = v['cd'] if v['cd'] }
  end
end
sorted_cd_key_cd_ids = cds.sort { |a,b| (a && b) ? (a1=a['cd_key'].match(/^(.*?)(\d+)/); b1=b['cd_key'].match(/^(.*?)(\d+)/) ; a1[1]==b1[1] ? (a1[2].to_i <=> b1[2].to_i) : (a1[1] <=> b1[1])) : ( a ? 1 : 0 ) }.collect { |cd| cd ? cd['id'] : 0 }
sorted_cd_key_cd_ids.each_index { |i| cds[sorted_cd_key_cd_ids[i]]['sort_order']=i if cds[sorted_cd_key_cd_ids[i]] }
print "var xsort_cds=new Object;\n";
print "xsort_cds['cd_keys']=[" + cds.collect { |cd| cd ? cd['sort_order'] : '' }.join(',') + "];\n";

sorted_cd_name_cd_ids = cds.sort { |a,b| (a && b) ? (a['cd_name'] <=> b['cd_name']) : ( a ? 1 : 0 ) }.collect { |cd| cd ? cd['id'] : 0 }
sorted_cd_name_cd_ids.each_index { |i| cds[sorted_cd_name_cd_ids[i]]['sort_order']=i if cds[sorted_cd_name_cd_ids[i]] }
print "xsort_cds['cd_names']=[" + cds.collect { |cd| cd ? cd['sort_order'] : '' }.join(',') + "];\n";

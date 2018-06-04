#!/usr/bin/env ruby

# By Michael Chaney, Michael Chaney Consulting Corporation
# Copyright 2006 Michael Chaney Consulting Corporation
# All Rights Reserved

# Puts together dd_search_strings.js based on the information in the
# tracks yaml file.  This way, the search terms are all in the file.

require 'pp'

SCRIPT_PATH = File.expand_path(File.dirname(__FILE__))
require "#{SCRIPT_PATH}/ms.rb"
include MS
require "#{SCRIPT_PATH}/tracks.rb"
include MSTracks

tracks = load_tracks

# Determine the start of the prior quarter, use that to determine if
# this is a new track.
date = Date.today
start_of_quarter = Date.new(date.year, (date.month-1)/3*3+1, 1)
if start_of_quarter.month==1
  start_of_prior_quarter = Date.new(start_of_quarter.year-1, 10, 1)
else
  start_of_prior_quarter = Date.new(start_of_quarter.year, start_of_quarter.month-3, 1)
end

$\ = nil

dd_eras=[]
dd_leads=[]
dd_tempos=[]
dd_libraries=[]
dd_orchestrations=[]
dd_genres=[]
dd_sub_genres=[]
dd_genres_and_sub_genres=[]
dd_moods=[]
dd_lyrical_themes=[]
dd_languages=[]
dd_instruments=[]
dd_bpms=[]
dd_keys=[]

dd_versions=[]
dd_cuts=[]
dd_cds=[]
dd_volumes=[]
dd_collections=[]
dd_cds_and_collections=[]
dd_subsets=[]

dd_composers=[]
dd_publishers=[]
dd_performers=[]

dd_registration_types=[]

dd_pros=[]

new_genres = {}

dd_mood_counts = [];
dd_genre_counts = [];
dd_sub_genre_counts = [];
dd_composer_counts = [];
dd_cd_counts = [];

tracks.each do |t|
  if t
    dd_eras[t['era']['id']] = t['era']['name'] if t['era']
    dd_tempos[t['tempo']['id']] = t['tempo']['name'] if t['tempo']
    dd_languages[t['language']['id']] = t['language']['name'] if t['language']
    dd_keys[t['key']['id']] = t['key']['name'] if t['key']
    dd_cds_and_collections[t['cds_and_collections']['id']] = { 'name' => t['cds_and_collections']['name'], 'subset_ids' => t['cds_and_collections']['subset_ids'] } if t['cds_and_collections']
    if t['bpm_range'] && !dd_bpms[t['bpm_range']['id']]
      br = t['bpm_range']
      if br['low_bpm'] == 0
        dd_bpms[t['bpm_range']['id']] = sprintf('Under %d', br['high_bpm']+1)
      elsif br['high_bpm'] == 999
        dd_bpms[t['bpm_range']['id']] = sprintf('%d+', br['low_bpm'])
      else
        dd_bpms[t['bpm_range']['id']] = sprintf('%d - %d', br['low_bpm'], br['high_bpm'])
      end
    end
    dd_libraries[t['library']['id']] = { 'name' => t['library']['name'], 'abbrev' => t['library']['abbrev'] } if t['library']
    dd_orchestrations[t['orchestration']['id']] = t['orchestration']['name'] if t['orchestration']

    t['leads'].each { |l| dd_leads[l['id'].to_i]=l['name'] }
  	 t['moods'].each { |m| dd_moods[m['id'].to_i]=m['name'] }
  	 t['lyrical_themes'].each { |lt| dd_lyrical_themes[lt['id'].to_i]=lt['theme'] }
  	 t['genres'].each { |g| dd_genres[g['id'].to_i]=g['name'] }
  	 t['sub_genres'].each { |sg| dd_sub_genres[sg['id'].to_i]={ 'name' => sg['name'], 'genre_id' => sg['genre_id'].to_i } }
  	 t['genres_and_sub_genres'].each { |gasg| dd_genres_and_sub_genres[gasg['id'].to_i]={ 'name' => gasg['name'], 'genre_id' => gasg['genre_id'], 'sub_genre_id' => gasg['sub_genre_id'] } }
  	 t['instruments'].each { |i| dd_instruments[i['id'].to_i]=i['name'] }
  	 t['performers'].each { |p| dd_performers[p['id'].to_i]=p['name'] }
  	 t['versions'].each { |v| v['cd']['subsets'].each { |s| dd_subsets[s['id'].to_i] = { 'id' => s['id'].to_i, 'name' => s['name'], 'description' => s['description'] } } if v['cd']['subsets'] }
  	 t['versions'].each { |v| dd_versions[v['version']['id'].to_i]={'name' => v['version']['name'], 'sort_order' => v['version']['sort_order'], 'has_vocal' => v['version']['has_vocal'] } }
  	 t['versions'].each { |v| dd_cuts[v['cut']['id'].to_i]={'name' => v['cut']['name'], 'sort_order' => v['cut']['sort_order'], 'default_version_id' => v['cut']['default_version_id'] } }
  	 t['versions'].each { |v| dd_cds[v['cd']['id'].to_i] ||= { 'id' => v['cd']['id'].to_i, 'cd_key' => v['cd']['cd_key'], 'cd_name' => v['cd']['cd_name'], 'library_id' => v['cd']['library_id'], 'new_release' => v['cd']['new_release'], 'cd_number' => v['cd']['cd_number'], 'cd_letter' => v['cd']['cd_letter'], 'volume_id' => v['cd']['volume_id'], 'subset_ids' => v['cd']['subsets'] ? v['cd']['subsets'].collect { |s| s['id'].to_i }.join(',') : '' } }
  	 t['versions'].each { |v| dd_volumes[v['cd']['volume']['id'].to_i] ||= {'id' => v['cd']['volume']['id'].to_i, 'volume_name' => v['cd']['volume']['volume_name'], 'volume_number' => v['cd']['volume']['volume_number'], 'collection_id' => v['cd']['volume']['collection_id'] } }
  	 t['versions'].each { |v| col=v['cd']['volume']['collection'] ; col['sort_order'] = col['sort_order'].to_i ; dd_collections[col['id'].to_i] ||= col }
  	 t['versions'].each { |v| cnc=v['cds_and_collections'] ; dd_cds_and_collections[cnc['id'].to_i] ||= { 'name' => cnc['name'], 'subset_ids' => cnc['subset_ids'] } }
  	 t['composers'].each { |c| dd_composers[c['id']]={ 'name' => c['contact_name'], 'pro_id' => c['pro']['id'] } }
  	 t['publishers'].each { |p| dd_publishers[p['id']]={ 'name' => p['name'], 'pro_id' => p['pro']['id'] } }

    t['composers'].each { |c| dd_pros[c['pro']['id']] = { 'abbreviation' => c['pro']['abbreviation'], 'country' => c['pro']['country'] } }
    t['publishers'].each { |p| dd_pros[p['pro']['id']] = { 'abbreviation' => p['pro']['abbreviation'], 'country' => p['pro']['country'] } }
    t['registration_codes'].each { |rc| rt=rc['registration_type'] ; dd_registration_types[rt['id']] = { 'id' => rt['id'], 'name' => rt['name'], 'pro_id' => rt['pro_id'], 'lookup_url_format' => rt['lookup_url_format'], 'validation_regexp' => rt['validation_regexp'] } }
    if DateTime.parse(t['created_at']) >= start_of_prior_quarter
      t['genres'].each do |g|
        new_genres[g['name']] = g['id']
      end
    end
    t['genres'].each do |g|
      dd_genre_counts[g['id'].to_i]||=0
      dd_genre_counts[g['id'].to_i]+=1
    end
    t['sub_genres'].each do |g|
      dd_sub_genre_counts[g['id'].to_i]||=0
      dd_sub_genre_counts[g['id'].to_i]+=1
    end
    t['moods'].each do |m|
      dd_mood_counts[m['id'].to_i]||=0
      dd_mood_counts[m['id'].to_i]+=1
    end
    t['composers'].each do |c|
      dd_composer_counts[c['id'].to_i]||=0
      dd_composer_counts[c['id'].to_i]+=1
    end
    t['versions'].each do |v|
      if v['cd']
        dd_cd_counts[v['cd']['id'].to_i]||=0
        dd_cd_counts[v['cd']['id'].to_i]+=1
      end
    end
  end
end

def put_dd(name, items)
  printf("var %s=[", name);
  items.each { |name| printf("\"%s\"", name.gsub(/"/,'\\"')) if name; print "," }
  puts "];\n\n";
end

def put_dd_count(name, items)
  printf("var %s=[", name);
  items.each { |cnt| print cnt if cnt; print "," }
  puts "];\n\n";
end

def put_o_dd(name, items, lookups)
  printf("var %s=[", name);
  items.each do |item|
    if item
      print "\n\t{ ";
      print lookups.collect { |l| item[l].kind_of?(String) ? sprintf("%s: \"%s\"", l, item[l].gsub(/"/, '\\"')) : sprintf("%s: %d", l, item[l]) }.join(", ")
      print " }"
    end
    print ","
  end
  puts "];\n\n";
end

last_blank=false
dd_cds_and_collections.each_index do |id|
  if dd_cds_and_collections[id]
    last_blank=false
  else
    dd_cds_and_collections[id] = { 'name' => '', 'subset_ids' => '' } unless last_blank
    last_blank=true
  end
end

last_subset_ids = ''
dd_cds_and_collections.reverse.each do |cnc|
  if cnc
    if cnc['name'] == ''
      cnc['subset_ids'] = last_subset_ids
    else
      last_subset_ids = cnc['subset_ids']
    end
  end
end

dd_tempos.each_index { |id| dd_tempos[id]=nil if dd_tempos[id] && dd_tempos[id] == 'Unknown' }

put_dd('dd_moods', dd_moods)
put_dd('dd_genres', dd_genres)
put_o_dd('dd_sub_genres', dd_sub_genres, ['name', 'genre_id'])
put_o_dd('dd_genres_and_sub_genres', dd_genres_and_sub_genres, ['name', 'genre_id', 'sub_genre_id'])
put_dd('dd_leads', dd_leads)
put_dd('dd_lyrical_themes', dd_lyrical_themes)
put_dd('dd_tempos', dd_tempos)
put_dd('dd_languages', dd_languages)
put_dd('dd_keys', dd_keys)
put_dd('dd_eras', dd_eras)
put_dd('dd_performers', dd_performers)
put_dd('dd_instruments', dd_instruments)
put_dd('dd_bpm_ranges', dd_bpms)
put_o_dd('dd_cds_and_collections', dd_cds_and_collections, ['name', 'subset_ids'])
put_o_dd('dd_versions', dd_versions, ['name', 'sort_order', 'has_vocal'])
put_o_dd('dd_cuts', dd_cuts, ['name', 'sort_order', 'default_version_id'])
put_o_dd('dd_libraries', dd_libraries, ['name', 'abbrev'])
put_o_dd('dd_cds', dd_cds, ['cd_key', 'cd_name', 'library_id', 'new_release', 'cd_number', 'cd_letter', 'volume_id', 'subset_ids'])
put_o_dd('dd_volumes', dd_volumes, ['volume_name', 'volume_number', 'collection_id'])
put_o_dd('dd_collections', dd_collections, ['collection_name', 'sort_order', 'collection_code', 'cd_name_format', 'cd_key_format', 'cd_key_regexp'])
put_o_dd('dd_subsets', dd_subsets, ['name', 'description'])
put_o_dd('dd_registration_types', dd_registration_types, [ 'name', 'pro_id', 'lookup_url_format', 'validation_regexp' ])
put_o_dd('dd_composers', dd_composers, ['name', 'pro_id'])
put_o_dd('dd_publishers', dd_publishers, ['name', 'pro_id'])
put_o_dd('dd_pros', dd_pros, [ 'abbreviation', 'country'])

print "var dd_new_genres=[" + new_genres.keys.sort.collect { |k| new_genres[k] }.join(',') + "];\n\n"

put_dd_count('dd_mood_counts', dd_mood_counts)
put_dd_count('dd_genre_counts', dd_genre_counts)
put_dd_count('dd_sub_genre_counts', dd_sub_genre_counts)
put_dd_count('dd_composer_counts', dd_composer_counts)
put_dd_count('dd_cd_counts', dd_cd_counts)

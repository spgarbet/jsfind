module MSTracks
  require 'yaml'

  unless defined?(SCRIPT_PATH)
    SCRIPT_PATH = File.expand_path(File.dirname(__FILE__))
  end

  DATA_FILE_PATH = "#{SCRIPT_PATH}/data"

  def table_filename(table_name)
    "#{DATA_FILE_PATH}/#{table_name}.yaml"
  end

  def check_data_directory
    if !File.exists?(DATA_FILE_PATH)
      File.makedirs(DATA_FILE_PATH)
    end
    if !File.directory?(DATA_FILE_PATH)
      raise "Directory \"#{DATA_FILE_PATH}\" exists, but is not a directory"
    end
  end

  def table_to_file(table_name)
    check_data_directory
    STDERR.puts "Getting #{table_name} from web site" if @debug
    table = get_table(table_name)
    File.open(table_filename(table_name), 'w') { |f| YAML.dump(table, f) }
    raise "Zero file size for #{table_name}" unless File.size?(table_filename(table_name))
  end

  def table_from_file(table_name, force_refresh=false)
    # if the file doesn't exist or it's more than 12 hours old, we'll grab a new one
    if force_refresh || !File.exists?(table_filename(table_name)) || !File.size?(table_filename(table_name)) || (Time.now - File.mtime(table_filename(table_name)) > 43200)
      table_to_file(table_name)
    end
    YAML.load_file(table_filename(table_name))
  end

  def refresh_data
    table_to_file('tracks')
    table_to_file('tracks_versions')
    table_to_file('versions')
    table_to_file('cuts')
    table_to_file('composers_tracks')
    table_to_file('payees')
    table_to_file('publishers_tracks')
    table_to_file('publishers')
    table_to_file('performers_tracks')
    table_to_file('performers')
    table_to_file('instruments_tracks')
    table_to_file('instruments')
    table_to_file('moods_tracks')
    table_to_file('moods')
    table_to_file('lyrical_themes_tracks')
    table_to_file('lyrical_themes')
    table_to_file('libraries')
    table_to_file('tempos')
    table_to_file('eras')
    table_to_file('orchestrations')
    table_to_file('genres_tracks')
    table_to_file('genres')
    table_to_file('sub_genres')
    table_to_file('sub_genres_tracks')
    table_to_file('leads_tracks')
    table_to_file('leads')
    table_to_file('languages')
    table_to_file('bpm_ranges')
    table_to_file('keys')
    table_to_file('pros')
    table_to_file('cds')
    table_to_file('volumes')
    table_to_file('collections')
    table_to_file('subsets')
    table_to_file('cds_subsets')
    table_to_file('registration_types')
    table_to_file('registration_codes')
  end

  def load_tracks
    tracks = table_from_file('tracks')
    tracks_versions = table_from_file('tracks_versions')
    versions = table_from_file('versions')
    cuts = table_from_file('cuts')
    composers_tracks = table_from_file('composers_tracks')
    payees = table_from_file('payees')
    publishers_tracks = table_from_file('publishers_tracks')
    publishers = table_from_file('publishers')
    performers_tracks = table_from_file('performers_tracks')
    performers = table_from_file('performers')
    instruments_tracks = table_from_file('instruments_tracks')
    instruments = table_from_file('instruments')
    moods_tracks = table_from_file('moods_tracks')
    moods = table_from_file('moods')
    lyrical_themes_tracks = table_from_file('lyrical_themes_tracks')
    lyrical_themes = table_from_file('lyrical_themes')
    libraries = table_from_file('libraries')
    tempos = table_from_file('tempos')
    eras = table_from_file('eras')
    orchestrations = table_from_file('orchestrations')
    genres_tracks = table_from_file('genres_tracks')
    genres = table_from_file('genres')
    sub_genres = table_from_file('sub_genres')
    sub_genres_tracks = table_from_file('sub_genres_tracks')
    leads_tracks = table_from_file('leads_tracks')
    leads = table_from_file('leads')
    languages = table_from_file('languages')
    bpm_ranges = table_from_file('bpm_ranges').compact.sort_by { |b| b['low_bpm'].to_i }
    keys = table_from_file('keys')
    pros = table_from_file('pros')
    cds = table_from_file('cds')
    volumes = table_from_file('volumes')
    collections = table_from_file('collections')
    subsets = table_from_file('subsets')
    cds_subsets = table_from_file('cds_subsets')
    registration_types = table_from_file('registration_types')
    registration_codes = table_from_file('registration_codes')

    STDERR.print "Putting big structure together...\n" if @debug
    
    # Make a nice new bpm list
    last_bpm = 0
    my_bpm_ranges = []
    bpm_ranges.each { |br| my_bpm_ranges.push( { 'low_bpm' => last_bpm, 'high_bpm' => br['low_bpm'].to_i-1 }) ; last_bpm = br['low_bpm'].to_i }
    my_bpm_ranges.push( { 'low_bpm' => last_bpm, 'high_bpm' => 999 })
    my_bpm_ranges.each_index { |id| my_bpm_ranges[id]['id'] = id }
    
    STDERR.puts "Adding subsets to cds..." if @debug
    cds_subsets.each do |cs|
      cd_id = cs['cd_id'].to_i
      subset_id = cs['subset_id'].to_i
      subset = subsets[subset_id]
      cds[cd_id]['subsets'] ||= []
      cds[cd_id]['subsets'].push({ 'id' => subset_id, 'name' => subset['name'], 'description' => subset['description'] })
    end
    
    # Make a list of collections and cds for the search dropdown.
    STDERR.puts "Making cds and collections..." if @debug
    cds_and_collections = []
    collections.compact.sort_by { |c| c['sort_order'].to_i }.each do |c|
      collection_cds = cds.compact.select { |cd| volumes[cd['volume_id'].to_i]['collection_id'].to_i == c['id'].to_i }.sort_by { |cd| cd['cd_key'] }
      collection_subset_ids = []
      collection_cds.each { |cd| cd['subsets'].each { |ss| collection_subset_ids.push ss['id'] } if cd['subsets'] }
      collection_subset_ids.uniq!
      STDERR.printf "  Collection %s, subset_ids: %s\n", c['collection_name'], collection_subset_ids.join(',') if @debug
      cds_and_collections.push({ 'cd_id' => 0, 'collection_id' => 0, 'name' => '', 'subset_ids' => collection_subset_ids.join(',') })
      cds_and_collections.push({ 'cd_id' => 0, 'collection_id' => c['id'].to_i, 'name' => sprintf('%s - All CDs', c['collection_name']), 'subset_ids' => collection_subset_ids.join(',') })
      collection_cds.each do |cd|
        cds_and_collections.push({ 'cd_id' => cd['id'].to_i, 'collection_id' => 0, 'name' => sprintf('%s - %s', cd['cd_key'], cd['cd_name']), 'subset_ids' => cd['subsets'] ? cd['subsets'].collect { |ss| ss['id'] }.join(',') : '' })
      end
    end
    cds_and_collections.each_index { |id| cds_and_collections[id]['id'] = id }
    
    STDERR.puts "Making genres and sub_genres..." if @debug
    genres_and_sub_genres = []
    genres.compact.sort_by { |g| g['name'] }.each do |g|
      # genre "header"
      genres_and_sub_genres.push( { 'genre_id' => g['id'], 'sub_genre_id' => nil, 'name' => g['name'] } )
      # and subgenres
      sub_genres.select { |sg| sg && sg['genre_id'] == g['id'] }.sort_by { |sg| sg['name'] }.each do |sg|
        genres_and_sub_genres.push( { 'genre_id' => nil, 'sub_genre_id' => sg['id'], 'name' => sg['name'] } )
      end
    end
    genres_and_sub_genres.each_index { |id| genres_and_sub_genres[id]['id'] = id }
    
    # set up initial arrays for subtables, and set up "belongs_to" joins
    tracks.each_with_index do |track, idx|
      next unless track
      if track['enabled'] != 't'
        tracks[idx] = nil
        next
      end
    
      track['versions'] = []
      track['composers'] = []
      track['publishers'] = []
      track['performers'] = []
      track['instruments'] = []
      track['leads'] = []
      track['genres'] = []
      track['sub_genres'] = []
      track['moods'] = []
      track['lyrical_themes'] = []
      track['registration_codes'] = []
      track['genres_and_sub_genres'] = []
    
      track['payee'] = payees[track['payee_id'].to_i] if track['payee_id']
      track['library'] = libraries[track['library_id'].to_i] if track['library_id']
      track['tempo'] = tempos[track['tempo_id'].to_i] if track['tempo_id']
      track['era'] = eras[track['era_id'].to_i] if track['era_id']
      track['orchestration'] = orchestrations[track['orchestration_id'].to_i] if track['orchestration_id']
      track['key'] = keys[track['key_id'].to_i] if track['key_id']
      track['language'] = languages[track['language_id'].to_i] if track['language_id']
    
      track['beats_per_minute'] = track['beats_per_minute'].to_i if track['beats_per_minute']
      if track['beats_per_minute']
        track['bpm_range']=my_bpm_ranges.detect { |b| b['low_bpm'].to_i <= track['beats_per_minute'] && b['high_bpm'] >= track['beats_per_minute'] }
        track['bpm_range_id']=track['bpm_range']['id'].to_i
      end
    
      track['explicit'] = (track['explicit']=='t')
      track['is_indie'] = (track['is_indie']=='t')
      track['is_arrangement'] = (track['is_arrangement']=='t')
      track['registered_with_pro'] = (track['registered_with_pro']=='t')
      track['registered_copyright'] = (track['registered_copyright']=='t')
    
      fix_stupid_quotes!(track['lyrics']) if track['lyrics']
    
    end
    
    STDERR.puts "Adding collections to volumes..." if @debug
    
    # add collection to volume
    volumes.each do |vol|
      if vol
        vol['collection'] = collections[vol['collection_id'].to_i] if vol['collection_id']
      end
    end
    
    STDERR.puts "Adding volumes to cds..." if @debug
    
    # and add volume to cd
    cds.each do |cd|
      if cd
        cd['volume'] = volumes[cd['volume_id'].to_i] if cd['volume_id']
      end
    end
    
    STDERR.puts "Adding versions to tracks..." if @debug
    
    # add tracks versions
    tracks_versions.each do |tv|
      if tv && tv['has_file']=='t'
        track_id = tv['track_id'].to_i
        track = tracks[track_id]
        next unless track
        tv['version'] = versions[tv['version_id'].to_i]
        tv['cut'] = cuts[tv['cut_id'].to_i]
        tv['pretty_version_name'] = pretty_version_name(tv['version'], tv['cut'])
        tv['cd'] = cds[tv['cd_id'].to_i] if tv['cd_id']
        mycd = cds_and_collections.detect { |cnc| cnc['cd_id'].to_i == tv['cd_id'].to_i }
        tv['cds_and_collections_id'] = mycd['id']
        tv['cds_and_collections'] = { 'id' => mycd['id'], 'name' => mycd['name'], 'subset_ids' => mycd['subset_ids'] }
        track['versions'].push tv
        mycol = cds_and_collections.detect { |cnc| cnc['collection_id'].to_i == tv['cd']['volume']['collection_id'].to_i }
        track['cds_and_collections_id'] = mycol['id']
        track['cds_and_collections'] = { 'id' => mycol['id'], 'name' => mycol['name'], 'subset_ids' => mycd['subset_ids'] }
      end
    end
    
    STDERR.puts "Remove tracks with no versions..." if @debug
    
    # remove tracks with no versions with files
    tracks.each_with_index do |track, idx|
      next unless track
      unless track['versions'].size > 0
        tracks[idx] = nil
        next
      end
    end
    
    STDERR.puts "Add composers..." if @debug
    
    # add track composers
    composers_tracks.each do |ct|
      if ct
        track_id = ct['track_id'].to_i
        track = tracks[track_id]
        next unless track
        payee_id = ct['payee_id'].to_i
        payee = payees[payee_id]
        pro_id = payee['pro_id'].to_i
        pro = pros[pro_id]
        track['composers'].push( { 'id' => payee['id'].to_i, 'percentage' => ct['percentage'].to_f, 'pro' => pro, 'cae_ipi_number' => payee['cae_ipi_number'], 'contact_name' => payee['contact_name'] })
      end
    end
    
    STDERR.puts "Add publishers..." if @debug
    
    # add track publishers
    publishers_tracks.each do |pt|
      if pt
        track_id = pt['track_id'].to_i
        track = tracks[track_id]
        next unless track
        publisher_id = pt['publisher_id'].to_i
        publisher = publishers[publisher_id]
        pro_id = publisher['pro_id'].to_i
        pro = pros[pro_id]
        track['publishers'].push( { 'id' => publisher['id'].to_i, 'percentage' => pt['percentage'].to_f, 'pro' => pro, 'cae_ipi_number' => publisher['cae_ipi_number'], 'name' => publisher['name'] })
      end
    end
    
    STDERR.puts "Add performers..." if @debug
    
    # add track performers
    performers_tracks.each do |pt|
      if pt
        track_id = pt['track_id'].to_i
        track = tracks[track_id]
        next unless track
        performer_id = pt['performer_id'].to_i
        performer = performers[performer_id]
        track['performers'].push( { 'id' => performer['id'].to_i, 'name' => performer['name'] } )
      end
    end
    
    STDERR.puts "Add instruments..." if @debug
    
    # add track instruments
    instruments_tracks.each do |pt|
      if pt
        track_id = pt['track_id'].to_i
        track = tracks[track_id]
        next unless track
        instrument_id = pt['instrument_id'].to_i
        instrument = instruments[instrument_id]
        track['instruments'].push( { 'id' => instrument['id'].to_i, 'name' => instrument['name'] } )
      end
    end
    
    STDERR.puts "Add leads..." if @debug
    
    # add track leads
    leads_tracks.each do |st|
      if st
        track_id = st['track_id'].to_i
        track = tracks[track_id]
        next unless track
        lead_id = st['lead_id'].to_i
        lead = leads[lead_id]
        track['leads'].push( { 'id' => lead['id'].to_i, 'name' => lead['name'] })
      end
    end
    
    STDERR.puts "Add genres..." if @debug
    
    # add track genres
    genres_tracks.each do |st|
      if st
        track_id = st['track_id'].to_i
        track = tracks[track_id]
        next unless track
        genre_id = st['genre_id'].to_i
        genre = genres[genre_id]
        track['genres'].push( { 'id' => genre['id'].to_i, 'name' => genre['name'] })
        track['genres_and_sub_genres'].push(genres_and_sub_genres.detect { |sasg| sasg['genre_id'] && sasg['genre_id']==st['genre_id'] })
      end
    end
    
    STDERR.puts "Add sub_genres..." if @debug
    
    # add track sub_genres
    sub_genres_tracks.each do |st|
      if st
        track_id = st['track_id'].to_i
        track = tracks[track_id]
        next unless track
        sub_genre_id = st['sub_genre_id'].to_i
        sub_genre = sub_genres[sub_genre_id]
        track['sub_genres'].push( { 'id' => sub_genre['id'].to_i, 'genre_id' => sub_genre['genre_id'].to_i, 'name' => sub_genre['name'], 'genre' => genres[sub_genre['genre_id'].to_i] })
        track['genres_and_sub_genres'].push(genres_and_sub_genres.detect { |sasg| sasg['sub_genre_id'] && sasg['sub_genre_id']==st['sub_genre_id'] })
      end
    end
    
    STDERR.puts "Add moods..." if @debug
    
    # add track moods
    moods_tracks.each do |mt|
      if mt
        track_id = mt['track_id'].to_i
        track = tracks[track_id]
        next unless track
        mood_id = mt['mood_id'].to_i
        mood = moods[mood_id]
        track['moods'].push( { 'id' => mood['id'].to_i, 'name' => mood['name'] })
      end
    end
    
    STDERR.puts "Add lyrical themes..." if @debug
    
    # add track lyrical_themes
    lyrical_themes_tracks.each do |ltt|
      if ltt
        track_id = ltt['track_id'].to_i
        track = tracks[track_id]
        next unless track
        lyrical_theme_id = ltt['lyrical_theme_id'].to_i
        lyrical_theme = lyrical_themes[lyrical_theme_id]
        track['lyrical_themes'].push( { 'id' => lyrical_theme['id'].to_i, 'theme' => lyrical_theme['theme'] })
      end
    end
    
    STDERR.puts "Add registration codes..." if @debug
    
    # add track registration_codes
    registration_codes.each do |rc|
      if rc
        track_id = rc['track_id'].to_i
        track = tracks[track_id]
        next unless track
        registration_type_id = rc['registration_type_id'].to_i
        registration_type = registration_types[registration_type_id]
        track['registration_codes'].push( { 'id' => rc['id'].to_i, 'code' => rc['code'], 'registration_type_id' => registration_type_id, 'registration_type' => registration_type })
      end
    end
    
    return tracks

  end

end

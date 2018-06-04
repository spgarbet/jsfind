module MS

  unless defined?(SCRIPT_PATH)
    SCRIPT_PATH = File.expand_path(File.dirname(__FILE__))
  end

  @@ms_default_bucket = 'music.mastersource.com'

  # Given a full filepath, returns a hash of the component parts:
  # path, cd_key, cd_track_number, title, quality, filetype
  # Alternately, this can also parse an old filename and give:
  # path, library, track_id, track_version_number, title, quality, filetype
  def parse_filepath(fname)
    
    if fname =~ /^(.*\/)?(\w+)(?: (.*?))?(?:\.(\d+k))?\.(aif|wav|mp3)/i
      path, track_key, title, quality, filetype = $1, $2, $3, $4, $5
      if title && title =~ /^\d+k$/ && !quality
        quality, title = title, nil
      end
      quality.downcase! if quality
      filetype.downcase!
      track_key.upcase!
      #STDERR.puts "path: #{path}\ntrack_key: #{track_key}\n\ntitle: #{title}\nquality: #{quality}\nfiletype: #{filetype}\n"
      return { 'path' => path, 'track_key' => track_key, 'title' => title, 'quality' => quality, 'filetype' => filetype }

    elsif fname =~ /^(.*\/)?(?:([a-z]\w*)\.)?(\d+)\.(\d+)(?:\.([^\/]*?))?(?:\.(\d+k))?(?:\.(mp3|wav|aif))/i
      path, library, track_id, track_version_number, title, quality, filetype = $1, $2, $3, $4, $5, $6, $7
      if title && title =~ /^\d+k$/ && !quality
        quality, title = title, nil
      end
      library.upcase! if library
      quality.downcase! if quality
      filetype.downcase!
      #STDERR.puts "path: #{path}\nlibrary: #{library}\ntrack_id: #{track_id}\nversion: #{track_version_number}\ntitle: #{title}\nquality: #{quality}\nfiletype: #{filetype}\n"
      return { 'path' => path, 'library' => library, 'track_id' => track_id, 'track_version_number' => track_version_number, 'title' => title, 'quality' => quality, 'filetype' => filetype }
    else
      nil
    end
  end

  @@remote_credentials = nil

  def get_remote_credentials(env=nil)
    require 'yaml'
    unless @@remote_credentials
      @@remote_credentials = YAML.load_file(SCRIPT_PATH + '/http_config.yml')
    end
    if env
      @@remote_credentials[env]
    elsif ENV['RAILS_ENV']
      @@remote_credentials[ENV['RAILS_ENV']]
    else
      @@remote_credentials['production']
    end
  end

  @@ms_xmlrpc_server = nil

  # Returns an XMLRPC server already connected
  def get_xmlrpc_server(env=nil)

    require 'yaml'
    require 'xmlrpc/client'

    unless @@ms_xmlrpc_server
      http_config = get_remote_credentials(env)
      @@ms_xmlrpc_server = XMLRPC::Client.new(http_config['server_name'], '/remote/api', http_config['server_port'], nil, nil, http_config['http_user'], http_config['http_pass'])
    end

    @@ms_xmlrpc_server
  end

  @@ms_track_cache = []
  # @@ms_track_keys["MSV01CD04_2"] = track_id
  @@ms_track_keys = {}

  # Given the pieces of a filepath (see parse_filepath), returns track info.
  def get_track_from_file_info(fpieces, env=nil)
    if fpieces['track_id']
      track_id = fpieces['track_id'].to_i
      unless @@ms_track_cache[track_id]
        server = get_xmlrpc_server(env)
        @@ms_track_cache[track_id] = server.call('FindTrackById', track_id)
        raise "Track not found: #{track_id}" unless @@ms_track_cache[track_id]
        @@ms_track_cache[track_id]['tracks_versions'].each do |tv|
          @@ms_track_cds_and_track_numbers["#{tv['cd']['cd_key']}.#{tv['cd_track_number']}"] = track_id
        end
      end
      @@ms_track_cache[track_id]

    elsif fpieces['track_key']
      track_id = @@ms_track_keys[fpieces['track_key']]
      unless track_id
        server = get_xmlrpc_server(env)
        track = server.call('FindTrackByTrackKey', fpieces['track_key'])
        raise "Track not found: #{lookup}" unless track
        track_id = track['id'].to_i
        @@ms_track_cache[track_id] = track
        @@ms_track_cache[track_id]['tracks_versions'].each do |tv|
          @@ms_track_keys[tv['track_key']] = track_id
        end
      end
      @@ms_track_cache[track_id]

    else
      raise "Cannot get track info without track_id or cd_key"
    end
  end

  @@ms_track_version_cache = {}
  # @@ms_track_version_track_key["MSV01CD04_2"] = "track_id.track_version_number"
  @@ms_track_version_track_key = {}

  # Given the pieces of a filepath (see parse_filepath), returns track info.
  def get_track_version_from_file_info(fpieces, env=nil)

    if fpieces['track_id'] && fpieces['track_version_number']
      track_id = fpieces['track_id'].to_i
      track_version_number = fpieces['track_version_number'].to_i
      lookup = "#{track_id}.#{track_version_number}"
      unless @@ms_track_version_cache[lookup]
        server = get_xmlrpc_server(env)
        @@ms_track_version_cache[lookup] = server.call('FindTrackVersionById', track_id, track_version_number)
        raise "Track version not found: #{lookup}" unless @@ms_track_version_cache[lookup]
        cd_key = @@ms_track_version_cache[lookup]['cd']['cd_key']
        cd_track_number = @@ms_track_version_cache[lookup]['cd_track_number']
        @@ms_track_version_track_key["#{cd_key}.#{cd_track_number}"] = lookup
      end
      @@ms_track_version_cache[lookup]

    elsif fpieces['track_key']
      lookup = @@ms_track_version_track_key[fpieces['track_key']]
      unless lookup
        server = get_xmlrpc_server(env)
        tv = server.call('FindTrackVersionByTrackKey', fpieces['track_key'])
        raise "Track not found: #{lookup}" unless tv
        track_id = tv['track_id'].to_i
        track_version_number = tv['track_version_number'].to_i
        lookup = "#{track_id}.#{track_version_number}"
        @@ms_track_version_cache[lookup] = tv
        @@ms_track_version_track_key[fpieces['track_key']] = lookup
      end
      @@ms_track_version_cache[lookup]

    else
      raise "Cannot get track version info without track_id and track_version_number or cd_key and cd_track_number"
    end
  end

  def helper_make_ext(q,f)
    if f == 'wav' || f == 'aif' then quality = ''
    elsif !q then raise "Don't know what to do: q=\"#{q}\" f=\"#{f}\""
    else quality = q + '.'
    end
    "#{quality}#{f}"
  end

  # Get the S3 asset name based on fpieces.
  def create_short_filename_from_fpieces(fpieces)
    f = fpieces['filetype']
    q = fpieces['quality']
    track_key = fpieces['track_key']
    if f && track_key
      ext = helper_make_ext(q,f)
      "#{track_key}.#{ext}"
    else
      raise "Cannot create short fname without cd_key and track #"
    end
  end

  # Pass in a tracks_version hash, plus quality (i.e. 128k or 192k) and
  # format (i.e. aif or wav), returns simple filename (no title/version).
  def create_short_filename(tv, q, f)
    ext = helper_make_ext(q,f)
    "#{tv['track_key']}.#{ext}"
  end

  # Pass in a tracks_version hash, plus quality (i.e. 128k or 192k) and
  # format (i.e. aif or wav), returns full filename (with title/version).
  def create_full_filename(tv, q, f)
    ext = helper_make_ext(q,f)
    title = tv['track']['title'].dup
    title.gsub!(/'|"/, ' ')
    title.gsub!(/[^A-Za-z0-9_ \-]/, '_')
    title.gsub!(/ /, '')
    prefix = "#{tv['track_key']} #{title}"
    # We cut this off at 27 characters, basically trying to keep aif name
    # under 32 characters long.
    prefix.slice!(27..10000) if prefix.length > 27
    "#{prefix}.#{ext}"
  end

  @@ms_aws_connection_info = nil

  def get_aws_connection(env = nil)
    unless @@ms_aws_connection_info
      server = get_xmlrpc_server(env)
      @@ms_aws_connection_info = server.call('GetAmazonKeys', env || 'production')
      @@ms_aws_connection_info[:bucket] ||= @@ms_default_bucket
    end
    @@ms_aws_connection_info
  end

  def establish_s3_connection(env = nil)
    require 'aws/s3'

    s3_config = get_aws_connection(env)

    AWS::S3::Base.establish_connection!(
      :access_key_id     => s3_config['access_key_id'],
      :secret_access_key => s3_config['secret_access_key'],
      :server            => s3_config['server'],
      :port              => s3_config['port'],
      :use_ssl           => s3_config['use_ssl'],
      :persistent        => s3_config['persistent']
    )

    return true
  end

  def reconstitute(str, name)
    if str=='\\N'
      nil
    elsif name=='id' || name=~/_id$/
      str.to_i
    else
      str.gsub(/\\r/, "\r").gsub(/\\n/, "\n").gsub(/\\t/, "\t")
    end
  end

  def tab_to_array_of_hashes(raw)
    ret = []
    lines = raw.split(/\r?\n/)
    cols = lines[0].split(/\t/)
    id_col = false
    cols.each_with_index { |c,n| id_col = n if c=='id' }
    lines.delete_at(0)
    lines.each do |l|
      row = {}
      l.split(/\t/).each_with_index { |c,n| row[cols[n]] = reconstitute(c,cols[n]) }
      if id_col
        ret[row['id'].to_i]=row
      else
        ret.push row
      end
    end
    ret
  end

  # Gets a table from the web site
  def get_table(table, env=nil)
    require 'net/http'
    http_config = get_remote_credentials(env)
    ret = false
    Net::HTTP.start(http_config['server_name'], http_config['server_port']) {|http|
      req = Net::HTTP::Get.new("/dumps/#{table}.txt")
      req.basic_auth http_config['http_user'], http_config['http_pass']
      resp = http.request(req)
      ret = tab_to_array_of_hashes(resp.body) if resp.code == '200'
    }
    ret
  end

  def fix_stupid_quotes!(s)
    s.gsub!(/\x82/,',')
    s.gsub!(/\x84/,',,')
    s.gsub!(/\x85/,'...')
    s.gsub!(/\x88/,'^')
    s.gsub!(/\x89/,'o/oo')
    s.gsub!(/\x8b/,'<')
    s.gsub!(/\x8c/,'OE')
    s.gsub!(/\x91|\x92/,"'")
    s.gsub!(/\x93|\x94/,'"')
    s.gsub!(/\x95/,'*')
    s.gsub!(/\x96/,'-')
    s.gsub!(/\x97/,'--')
    s.gsub!(/\x98/,'~')
    s.gsub!(/\x99/,'TM')
    s.gsub!(/\x9b/,'>')
    s.gsub!(/\x9c/,'oe')
    s
  end

  def pretty_version_name(version, cut)
    if cut['default_version_id'].nil?
      version['name']
    elsif version['id'].to_i == cut['default_version_id'].to_i
      cut['name']
    else
      "#{cut['name']} #{version['name']}"
    end
  end

  def normalize_track_key(key, cd_key_regexp, cd_key_format)
    if key =~ /^#{cd_key_regexp}_(\d+)( |$)/i
      volnum, cd_num, cd_let, track_num = $1, $2.to_i, $3, $4.to_i
      volnum=volnum.to_i if volnum=~/^\d+$/
      cd_let.downcase! if cd_let
      sprintf("#{cd_key_format}_%4$02d", volnum, cd_num, cd_let, track_num)
    else
      nil
    end
  end
end

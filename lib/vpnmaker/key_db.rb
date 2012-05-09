module VPNMaker
  class KeyDB
    def initialize(path)
      @path = path
      @db = File.exists?(path) ? YAML.load_file(path) : {}
      @touched = false
    end

    def [](k); @db[k]; end

    def []=(k, v)
      @db[k] = v
      @db[:modified] = Time.now
      @touched = true
    end

    def touched!
      @touched = true
      @db[:modified] = Time.now
    end


    def datadir; self[:datadir]; end

    def data_path(k)
      File.join(File.dirname(@path), self.datadir, k)
    end

    def dump(k, v, overwrite=false)
      p = data_path(k)
      raise "#{k} already exists" if File.exists?(p) && !overwrite
      File.open(p, 'w') {|f| f.write(v)}
      @touched = true
    end

    def data(k)
      File.exists?(data_path(k)) ? File.read(data_path(k)) : nil
    end

    def disk_version
      File.exists?(@path) ? YAML.load_file(@path)[:version] : 0
    end

    def sync
      if disk_version == @db[:version]
        if @touched
          FileUtils.mkdir_p(File.dirname(@path) + "/" + self.datadir)
          @db[:version] += 1
          File.open(@path, 'w') {|f| f.write(@db.to_yaml)}
          true
        else
          false
        end
      else
        raise "Disk version of #{@path} (#{disk_version}) != loaded version (#{@db[:version]}). " + \
        "Try reloading and making your changes again."
      end
    end

    def version; @db[:version]; end
  end
end

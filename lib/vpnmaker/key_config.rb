module VPNMaker
  class KeyConfig
    def initialize(path)
      @config = YAML.load_file(path)
    end

    def [](k); @config[k]; end
  end
end

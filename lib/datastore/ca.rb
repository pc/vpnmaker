module VPNMaker
  module DataStore
    class CA
      include DataMapper::Resource

      property :id, Serial
      property :updated_at, DateTime
      property :created_at, DateTime

      property :name, String
      property :country, String
      property :province, String
      property :city, String
      property :organization, String
      property :email, String

      DataMapper::Model.raise_on_save_failure = true
      DataMapper.finalize
      DataMapper.auto_upgrade!
    end
  end
end

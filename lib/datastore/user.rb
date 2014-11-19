module VPNMaker
  module DataStore
    class User
      include DataMapper::Resource

      property :id, Serial
      property :updated_at, DateTime
      property :created_at, DateTime

      property :cn, String
      property :name, String
      property :email, String
      property :active_key, Integer
      property :revoked, Object

      def user; cn; end;

      DataMapper::Model.raise_on_save_failure = true
      DataMapper.finalize
      DataMapper.auto_upgrade!
    end
  end
end

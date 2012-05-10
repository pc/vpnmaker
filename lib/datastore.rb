module VPNMaker
  module DataStore
    require 'dm-core'
    require 'dm-do-adapter'
    require 'dm-observer'
    require 'dm-migrations'
    require 'dm-timestamps'
    require 'dm-serializer'
    require 'dm-validations'
    require 'dm-aggregates'
    require 'dm-types'
    #require 'do_mysql'
    require 'dm-mysql-adapter'

    # require 'base64'
    # require 'chronic'
    # require 'phony'

    # require 'ansi/mixin'
    # require 'ansi/progressbar'
    # require 'ansi/table'
    # require 'percentise'
    # require 'stamp'

    # require 'munger'
    # require 'ruport'
    # require 'ruport/util'

    # require 'dm-sqlite-adapter'
    # require 'do_sqlite3'

    # DataMapper::Logger.new($stdout, :debug)

    path = (File.dirname File.expand_path(__FILE__)) + "/"
    autoload :User, "#{path}datastore/user"
    autoload :CA, "#{path}datastore/ca"

    DataMapper.setup(:default, {
                       :host => '127.0.0.1',
                       :port => 3306,
                       :database => 'vpnmaker',
                       :adapter => 'mysql',
                       :username => 'root',
                       :password => 'gavno.123!'})

  end
end

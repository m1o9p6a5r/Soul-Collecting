#
#  Manages the MongoDB shards
#

require 'mongoid'

module RCS
module DB

class Shard
  extend RCS::Tracer

  def self.count
    db = Mongo::Connection.new("localhost").db("admin")
    list = db.command({ listshards: 1 })
    list['shards'].size
  end

  def self.all
    db = Mongo::Connection.new("localhost").db("admin")
    db.command({ listshards: 1 })
  end

  def self.create(host)
    trace :info, "Creating new shard: #{host}"
    begin
      db = Mongo::Connection.new("localhost").db("admin")
      db.command({ addshard: host })
    rescue Exception => e
      {'errmsg' => e.message, 'ok' => 0}
    end
  end

  def self.destroy(host)
    trace :info, "Destroying shard: #{host}"
    begin
      db = Mongo::Connection.new("localhost").db("admin")
      db.command({ removeshard: host })
    rescue Exception => e
      {'errmsg' => e.message, 'ok' => 0}
    end
  end

  def self.find(id)
    begin
      self.all['shards'].each do |shard|
        if shard['_id'] == id
          host, port = shard['host'].split(':')
          db = Mongo::Connection.new(host, port.to_i).db("rcs")
          return db.stats
        end
      end
      {'errmsg' => 'Id not found', 'ok' => 0}
    rescue Exception => e
      {'errmsg' => e.message, 'ok' => 0}
    end
  end

  def self.enable(database)
    begin
      db = Mongo::Connection.new("localhost").db("admin")
      db.command({ enablesharding: database })
    rescue Exception => e
      error = db.command({ getlasterror: 1})
      error['err']
    end
  end

  def self.set_key(collection, key)
    #trace :info, "Enabling shard key #{key.inspect} on #{collection.stats['ns']}"
    begin
      # we need an index before the creation of the shard
      collection.create_index(key.to_a)
      # switch to 'admin' and create the shard
      db = Mongo::Connection.new("localhost").db("admin")
      db.command({ shardcollection: collection.stats['ns'], key: key })
    rescue Exception => e
      e.message
    end
  end
  
end

end #DB::
end #RCS::
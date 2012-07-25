require "redis"
require "json"

class Sethandler < Redis::Client
  
  def initialize(client,check)
    @redis = Redis.new
    @client = client
    @check = check
  end
  
  def set_event(occtime)
    @redis.hset('handler:' + @client, @check, {:occtime => occtime}.to_json)
  end
  
  def put_event
    pevent = @redis.hget('handler:' + @client, @check)
    unless pevent == nil
      ::JSON.parse(pevent)["occtime"]
    end
  end
end
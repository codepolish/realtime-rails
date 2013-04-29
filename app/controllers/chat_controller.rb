class ChatController < ApplicationController
  def index
    socket = env['rack.hijack'].call
    handshake = WebSocket::Handshake::Server.new
    handshake.from_rack env
    socket.write handshake.to_s
    subRedis = Redis.new :timeout => 0
    pubRedis = Redis.new
    user_id = pubRedis.incr('chat-connections')
    subThread = Thread.new do
      subRedis.subscribe('chat-broadcast') do |on|
        on.message do |channel, msg|
          frame = WebSocket::Frame::Outgoing::Server.new(version: handshake.version, type: 'text', data: msg)
          socket.write frame.to_s
        end
      end
    end

    Thread.new do
      buffer = WebSocket::Frame::Incoming::Server.new(version: handshake.version)
      while !socket.closed? do
        data = socket.recvfrom(2000).first
        buffer << data
        while frame = buffer.next do
          if frame.type == :close
            socket.close
          else
            data = JSON.parse(frame.data) rescue {}
            if data['username']
              item = JSON.dump({:members => pubRedis.hgetall('chat-members').map { |e| {user_id: e.first, username: e.last}}})
              frame = WebSocket::Frame::Outgoing::Server.new(version: handshake.version, type: 'text', data: item)
              socket.write frame.to_s
              item = JSON.dump({:log => pubRedis.lrange('chat-log', 0, pubRedis.llen('chat-log')).map { |e| JSON.parse(e) }})
              frame = WebSocket::Frame::Outgoing::Server.new(version: handshake.version, type: 'text', data: item)
              socket.write frame.to_s
              @username = data['username']
              pubRedis.hset('chat-members', user_id, @username)
              item = JSON.dump({:add => true, :member => { :user_id => user_id, :username => @username }})
              pubRedis.publish('chat-broadcast', item)
            end
            if data['message']
              item =  JSON.dump({:from => @username, :message => data['message']})
              pubRedis.rpush('chat-log', item)
              pubRedis.publish('chat-broadcast', item)
            end
          end
        end
      end
      pubRedis.hdel('chat-members', user_id)
      pubRedis.publish('chat-broadcast', JSON.dump({:remove => true, :member => { :user_id => user_id, :username => @username }}))
      pubRedis.rpush('chat-log', JSON.dump({notice: "#{@username} has disconnected"}))
      subRedis.unsubscribe('chat-broadcast')
      subThread.kill
    end
    render :nothing => :true, :status => :ok
  end
end

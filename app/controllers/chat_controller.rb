class ChatController < ApplicationController
  def index
    socket = env['rack.hijack'].call
    handshake = WebSocket::Handshake::Server.new
    handshake.from_rack env
    socket.write handshake.to_s
    subRedis = Redis.new :timeout => 0
    pubRedis = Redis.new
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
          log_items = []
          if frame.type == :close
            socket.close
          else
            data = JSON.parse(frame.data) rescue {}
            if data['username']
              @username = data['username']
              log_items << JSON.dump({:add => @username})
            end
            if data['message']
              log_items << JSON.dump({:from => @username, :message => data['message']})
            end
            while log_items.present?
              pubRedis.publish('chat-broadcast', log_items.pop)
            end
          end
        end
      end
      pubRedis.publish('chat-broadcast', JSON.dump({:remove => @username}))
      subRedis.unsubscribe('chat-broadcast')
      subThread.kill
    end
    render :nothing => :true, :status => :ok
  end
end

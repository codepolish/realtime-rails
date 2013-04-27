class ChatController < ApplicationController
  include ActionController::Live

  def index
    socket = env['rack.hijack'].call
    handshake = WebSocket::Handshake::Server.new
    handshake.from_rack env
    socket.write handshake.to_s
    subRedis = Redis.new :timeout => 0
    pubRedis = Redis.new
    Thread.new do
      subRedis = Redis.new :timeout => 0
      subRedis.subscribe('broadcast') do |on|
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
        while frame = buffer.next
          if frame.type == :close
            socket.close
          else
            data = JSON.parse(frame.data) rescue {}
            if data['username']
              @username = data['username']
              pubRedis.publish('broadcast', JSON.dump({:notice  => "#{@username} has joined"}))
            end
            if data['message']
              pubRedis.publish('broadcast', JSON.dump({:from => @username, :message => data['message']}))
            end
          end
        end
      end
      pubRedis.publish('broadcast', JSON.dump({:notice  => "#{@username} has disconnected"}))
      subRedis.unsubscribe('broadcast')
    end
    render :nothing => :true, :status => :ok
  end
end

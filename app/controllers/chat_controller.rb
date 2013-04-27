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

    pubRedis.publish('broadcast', 'New User Connected!')

    Thread.new do
      buffer = WebSocket::Frame::Incoming::Server.new(version: handshake.version)
      while !socket.closed? do
        data = socket.recvfrom(2000).first
        buffer << data
        while frame = buffer.next
          pubRedis.publish('broadcast', frame.data)
        end
      end
      subRedis.unsubscribe('broadcast')
    end
    render :nothing => :true, :status => :ok
  end
end

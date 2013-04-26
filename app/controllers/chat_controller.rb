class ChatController < ApplicationController
  include ActionController::Live

  def index
    Thread.new do
      socket = env['rack.hijack'].call
      handshake = WebSocket::Handshake::Server.new
      handshake.from_rack env
      socket.write handshake.to_s
      Thread.new do
        redis = Redis.new :timeout => 0
        redis.subscribe('broadcast') do |on|
          on.message do |channel, msg|
            frame = WebSocket::Frame::Outgoing::Server.new(version: handshake.version, type: 'text', data: msg)
            socket.write frame.to_s
          end
        end
      end

      redis = Redis.new
      redis.publish('broadcast', 'New User Connected!')

      Thread.new do
        buffer = WebSocket::Frame::Incoming::Server.new(version: handshake.version)
        while !socket.closed? do
          data = socket.recvfrom(2000).first
          buffer << data
          while frame = buffer.next
            redis.publish('broadcast', frame.data)
          end
        end
      end
    end
    render :nothing => :true, :status => :ok
  end
end

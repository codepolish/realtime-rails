class DrawController < ApplicationController
  def index
    socket = env['rack.hijack'].call
    handshake = WebSocket::Handshake::Server.new
    handshake.from_rack env
    socket.write handshake.to_s
    subRedis = Redis.new :timeout => 0
    pubRedis = Redis.new
    user_id = "user-#{pubRedis.incr('draw-connections')}"
    subThread = Thread.new do
      subRedis.subscribe('draw-broadcast') do |on|
        on.message do |channel, msg|
          frame = WebSocket::Frame::Outgoing::Server.new(version: handshake.version, type: 'text', data: msg)
          socket.write frame.to_s
        end
      end
    end

    frame = WebSocket::Frame::Outgoing::Server.new(version: handshake.version, type: 'text', data: JSON.dump({connect: user_id}))
    socket.write frame.to_s

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
            pubRedis.publish('draw-broadcast', JSON.dump(data.merge(user_id: user_id)))
          end
        end
      end
      subRedis.unsubscribe('draw-broadcast')
      subThread.kill
    end
    render :nothing => :true, :status => :ok
  end

end

class TimeController < ActionController::Base
  include ActionController::Live

  def index
    begin
      response.headers['Content-Type'] = 'text/event-stream'
      100.times {
        response.stream.write "event: time\n"
        data = JSON.dump({time: Time.now })
        response.stream.write "data: #{data}\n\n"
        sleep 1
      }
    rescue
    ensure
      response.stream.close
    end
  end
end

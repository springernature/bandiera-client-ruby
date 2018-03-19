module Bandiera
  class Client
    class Error < StandardError
    end

    class TimeoutError < Bandiera::Client::Error
    end

    class ResponseError < Bandiera::Client::Error
    end
  end
end

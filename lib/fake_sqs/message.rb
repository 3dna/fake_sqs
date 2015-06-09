require 'securerandom'

module FakeSQS
  class Message

    attr_reader :body, :id, :md5, :attributes
    attr_accessor :visibility_timeout

    def initialize(options = {})
      @body = options.fetch("MessageBody")
      @id = options.fetch("Id") { SecureRandom.uuid }
      @md5 = options.fetch("MD5") { Digest::MD5.hexdigest(@body) }
      @attributes = default_attributes.merge(options["Attributes"] || {})
    end

    def expire!
      self.visibility_timeout = nil
    end

    def expired?( limit = Time.now )
      self.visibility_timeout.nil? || self.visibility_timeout < limit
    end

    def expire_at(seconds)
      self.visibility_timeout = Time.now + seconds
    end

    private
    def default_attributes
      {
        "SenderId" => SecureRandom.hex,
        "SentTimestamp" => Time.now.to_i,
        "ApproximateReceiveCount" => 0,
        "ApproximateFirstReceiveTimestamp" => Time.now.to_i
      }
    end

  end
end

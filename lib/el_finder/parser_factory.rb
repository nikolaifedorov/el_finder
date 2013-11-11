class ParserFactory

  class << self

    def json(response)
      JSON.parse response
    rescue JSON::ParserError
      {}
    end

  end

end

class RestFilesystem

  class << self

    def init(rest_file_options)
      RestSettings.init(rest_file_options)
      SERVER_URL = RestSettings.filesystem_server
    end


    def get(params = {})
      validation
      request :get, SERVER_URL, params(params)
    end


    private

    def validation
      raise Errno::ENOENT, "'SERVER_URL' constant was not initialized." if SERVER_URL.nil?
    end


    # configure parser for response
    def parser(response)
      ParserFactory.json(response)
    end


    # params for request
    def params(params)
      request_params = { params: params }
    end


    # send request
    def request(method, *args)
      parser( RestClient.send(method, *args) )
    end

  end # self

end # RestFilesystem
require 'settingslogic'

class RestSettings < Settingslogic

  class << self

    def init(file_name = "application.yml")
      source default_source(file_name)
      namespace default_namespace
    end


    def default_source(file_name = "application.yml")
      "#{Rails.root}/config/#{file_name}"
    end


    def default_namespace
      Rails.env
    end  

  end # self

end # RestSettings

class RestSettings < Settingslogic

  class << self

    def init(file_name = "application.yml")
      source "#{Rails.root}/config/#{file_name}"
      namespace Rails.env
    end

  end # self

end

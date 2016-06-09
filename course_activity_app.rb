require 'bundler/setup'
require 'wolf_core'
require 'csv'
require 'time'

Dir["./helpers/*"].each {|f| require f }

class CourseActivityApp < WolfCore::App
  set :root, File.dirname(__FILE__)
  self.setup

  helpers TimeHelper, DataHelper, SortHelper

  get '/' do
    @data = {}
    CSV.parse(URI.decode(params['accessData']), headers:true) do |row|
      category = substitute_category(row["Category"])
      @data[category] ||= {}
      @data[category] = update_category_data(@data[category], row)
    end

    slim :index
  end

  get '/access-report.js' do
    content_type 'application/javascript'
    erb 'access-report.js'.to_sym
  end
end

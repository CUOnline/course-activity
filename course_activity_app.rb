require 'bundler/setup'
require 'wolf_core'
require 'csv'
require 'time'

Dir["./helpers/*"].each {|f| require f }

class CourseActivityApp < WolfCore::App
  set :root, File.dirname(__FILE__)
  self.setup

  set :public_paths, [/^\/upload$/, /^\/access-report.js$/, /^\/check-data\/\d+$/]

  helpers TimeHelper, DataHelper, SortHelper

  before do
    params['sort'] ||= 'name'
    params['csvData'] ||= ''

    headers 'Access-Control-Allow-Origin' => settings.canvas_url
  end

  post '/upload' do
    redis_key = "course:#{params['courseId']}:access_data"

    if settings.redis.exists(redis_key)
      redirect "course/#{params['courseId']}"
    else
      @data = {}
      begin
        CSV.parse(URI.decode(params['csvData']), headers:true) do |row|
          category = substitute_category(row['Category'])
          @data[category] ||= {}
          @data[category] = update_category_data(@data[category], row)
        end
        settings.redis.set("course:#{params['courseId']}:csv_data", params['csvData'])
        settings.redis.set(redis_key, @data.to_json)
      rescue CSV::MalformedCSVError
        status 400
        body 'Invalid CSV data provided'
      end
    end
  end

  get '/course/:course_id' do
    redis_key = "course:#{params[:course_id]}:access_data"
    if settings.redis.exists(redis_key)
      @data = JSON.parse(settings.redis.get(redis_key))
    else
      @data = {}
    end
    slim :index
  end

  get '/access-report.js' do
    content_type 'application/javascript'
    erb 'access-report.js'.to_sym
  end
end

require 'bundler/setup'
require 'wolf_core'

require 'csv'
require 'time'

Dir["./helpers/*"].each {|f| require f }

class CourseActivityApp < WolfCore::App
  set :root, File.dirname(__FILE__)
  set :allowed_roles, ['AccountAdmin', 'TeacherEnrollment']
  set :auth_paths, [/course\/\d+/, /download\/\d+/, /reload/]

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
        csv_string = URI.decode(params['csvData'])
        CSV.parse(csv_string, headers:true) do |row|
          category = substitute_category(row['Category'] || '')
          @data[category] ||= {}
          @data[category] = update_category_data(@data[category], row)
        end
        settings.redis.set("course:#{params['courseId']}:csv_data", csv_string)
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
      @data = JSON.parse(settings.redis.get(redis_key).force_encoding('UTF-8'))
    else
      @data = {}
    end
    slim :index
  end

  post '/reload' do
    csv_file = File.join(settings.tmp_dir, "access_data_#{params[:course_id]}.csv")
    File.delete(csv_file) if File.exists?(csv_file)

    settings.redis.del("course:#{params[:course_id]}:access_data")
    settings.redis.del("course:#{params[:course_id]}:csv_data")
    slim :reload
  end

  get '/download/:course_id' do
    redis_key = "course:#{params[:course_id]}:csv_data"

    if settings.redis.exists(redis_key)
      csv_file = File.join(settings.tmp_dir, "access_data_#{params[:course_id]}.csv")
      if !File.exists?(csv_file)
        CSV.open(csv_file, 'w+') do |csv|
          CSV.parse(settings.redis.get(redis_key).force_encoding('UTF-8')).each do |row|
            csv << row
          end
        end
      end
      content_type 'text/csv'
      send_file csv_file
    else
      slim :download
    end
  end

  get '/check-data/:course_id' do
    settings.redis.exists("course:#{params[:course_id]}:access_data") ? '1' : ''
  end

  get '/access-report.js' do
    content_type 'application/javascript'
    erb 'access-report.js'.to_sym
  end

  get '/canvas-example.js' do
    content_type 'application/javascript'
    erb 'canvas-example.js'.to_sym, {
      :locals => {
        'scheme'=> request.env['rack.url_scheme'],
        'domain'=> request.env['HTTP_HOST'],
        'mount' => mount_point
      }
    }
  end

  get '/about' do
    slim :about
  end

  # These filters are a hack to use the default wolf_core CSS for the about page,
  # instead of the CourseActivityApp CSS which overrides it. Disable app-specific
  # CSS before the request, re-enable in the after.
  before '/about' do
    CourseActivityApp.enable :exclude_css
  end
  after '/about' do
    CourseActivityApp.disable :exclude_css
  end
end

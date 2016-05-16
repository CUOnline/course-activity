require 'bundler/setup'
require 'wolf_core'
require 'csv'

class CourseActivityApp < WolfCore::App
  set :root, File.dirname(__FILE__)
  self.setup

  post '/' do
  end

  get '/access-report.js' do
    content_type 'application/javascript'
    erb 'access-report.js'.to_sym
  end
end

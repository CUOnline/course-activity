require 'bundler/setup'
require 'wolf_core'
require 'csv'

class CourseActivityApp < WolfCore::App
  set :root, File.dirname(__FILE__)
  self.setup

  get '/' do
  end
end

require 'bundler/setup'
require 'wolf_core'
require 'csv'
require 'time'

class CourseActivityApp < WolfCore::App
  set :root, File.dirname(__FILE__)
  self.setup

  helpers do
    def first_timestamp(data, row)
      current = Time.parse( data['First Access'] || Time.now.to_s )
      return current.to_s unless Time.parse(row['First Access']) < current

      row['First Access']
    end

    def last_timestamp(data, row)
      current = Time.parse( data['Last Access'] || '1970-1-1' )
      return current.to_s unless Time.parse(row['Last Access']) > current

      row['Last Access']
    end

    def student_data(row)
      {
        'Display Name' => row["Display Name"],
        'Views' => row['Views'] || 0,
        'Participations' => row['Participations'] || 0,
        'First Access' => row['First Access'],
        'Last Access' => row['Last Access']
      }
    end

    def substitute_category(category)
      substitutions = {
        'wiki' => 'pages',
        'topics' => 'discussions',
        'roster' => 'people',
        'pages' => 'group pages'
      }

      category = substitutions[category] if substitutions.keys.include?(category)
      category.capitalize
    end

    def update_item_data(data, row)
      data['Title'] ||= row["Title"]

      data['Total Views'] ||= 0
      data['Total Views'] += row['Views'].to_i || 0

      data['Total Participations'] ||= 0
      data['Total Participations'] += row['Participations'].to_i || 0

      data['accesses'] ||= []
      data['accesses'] << student_data(row)

      data['First Access'] = first_timestamp(data, row)
      data['Last Access'] = last_timestamp(data, row)

      data
    end

    def update_category_data(data, row)
      data['Total Views'] ||= 0
      data['Total Views'] += row['Views'].to_i || 0

      data['Total Participations'] ||= 0
      data['Total Participations'] += row['Participations'].to_i || 0

      data["accesses"] ||= {}
      data["accesses"][row["Code"]] ||= {}
      data["accesses"][row["Code"]] = update_item_data(data["accesses"][row["Code"]], row)

      data['First Access'] = first_timestamp(data, row)
      data['Last Access'] = last_timestamp(data, row)

      data
    end
  end

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

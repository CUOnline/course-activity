require 'bundler/setup'
require 'wolf_core'
require 'csv'
require 'time'

class CourseActivityApp < WolfCore::App
  set :root, File.dirname(__FILE__)
  self.setup

  helpers do
    def format_time(timestamp)
      Time.parse(timestamp).strftime('%m/%d/%y %H:%M')
    end

    def sort_link(field)
      url = mount_point + '?sort='
      if params['sort'] == field
        url += "#{field}-desc"
      else
        url += field
      end

      url
    end

    def sort_class(header, sort_by)
      case sort_by
        when header
          'glyphicon glyphicon-triangle-bottom'
        when "#{header}-desc"
          'glyphicon glyphicon-triangle-top'
        else
          ''
      end
    end

    def sorted_keys(hash, sort_by='name')
      sort_key, sort_order = sort_by.split('-')

      sorted = hash.keys.sort_by do |k|
        value = hash[k][sort_key] || k
        value = Time.parse(value) if ['first-access', 'last-access'].include?(k)
        value
      end

      sort_order == 'desc' ? sorted.reverse : sorted
    end

    def first_timestamp(data, row)
      current = Time.parse( data['first-access'] || Time.now.to_s )
      return current.to_s unless Time.parse(row['First Access']) < current

      row['First Access']
    end

    def last_timestamp(data, row)
      current = Time.parse( data['last-access'] || '1970-1-1' )
      return current.to_s unless Time.parse(row['Last Access']) > current

      row['Last Access']
    end

    def substitute_category(category)
      substitutions = {
        'wiki' => 'pages',
        'topics' => 'discussions',
        'roster' => 'people',
        'pages' => 'group pages',
        'external_tools' => 'external tools'
      }

      category = substitutions[category] if substitutions.keys.include?(category)
      category.capitalize
    end

    def student_data(row)
      {
        'name' => row['Display Name'],
        'views' => row['Views'].to_i || 0,
        'participations' => row['Participations'].to_i || 0,
        'first_access' => row['First Access'],
        'last_access' => row['Last Access']
      }
    end

    def update_item_data(data, row)
      data = update_data(data, row)
      data['name'] ||= row['Title']
      data['accesses'][row['User ID']] ||= {}
      data['accesses'][row['User ID']] = student_data(row)
      data
    end

    def update_category_data(data, row)
      data = update_data(data, row)
      data['accesses'][row['Code']] ||= {}
      data['accesses'][row['Code']] = update_item_data(data['accesses'][row['Code']], row)
      data
    end

    def update_data(data, row)
      data['views'] ||= 0
      data['views'] += row['Views'].to_i || 0

      data['participations'] ||= 0
      data['participations'] += row['Participations'].to_i || 0

      data['first_access'] = first_timestamp(data, row)
      data['last_access'] = last_timestamp(data, row)
      data["accesses"] ||= {}

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

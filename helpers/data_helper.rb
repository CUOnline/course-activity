module DataHelper
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
    data['accesses'] ||= {}

    data
  end
end

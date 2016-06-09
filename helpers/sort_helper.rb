module SortHelper
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
end

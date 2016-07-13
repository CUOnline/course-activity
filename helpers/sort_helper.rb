module SortHelper
  def sort_link(header, sort_by, course_id)
    url = "#{mount_point}/course/#{course_id}?sort="
    if sort_by == header
      url += "#{header}-desc"
    else
      url += header
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
    key_parts = sort_by.split('-')
    if key_parts.length == 3
      sort_order = key_parts.pop
      sort_key = key_parts.join('-')
    elsif ['first-access', 'last-access'].include?(sort_by)
      sort_key = sort_by
    else
      sort_key, sort_order = key_parts
    end

    sorted = hash.keys.sort_by do |k|
      value = hash[k][sort_key] || k
      value = Time.parse(value) if ['first-access', 'last-access'].include?(k)
      value
    end

    sort_order == 'desc' ? sorted.reverse : sorted
  end
end

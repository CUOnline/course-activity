module TimeHelper
  def format_time(timestamp)
    Time.parse(timestamp).strftime('%m/%d/%y %H:%M')
  end

  def first_timestamp(data, row)
    current = Time.parse( data['first-access'] || Time.now.to_s )
    return current.to_s unless Time.parse(row['First Access'] || Time.now.to_s) < current

    row['First Access']
  end

  def last_timestamp(data, row)
    current = Time.parse( data['last-access'] || '1970-1-1' )
    return current.to_s unless Time.parse(row['Last Access'] || '1970-1-1') > current

    row['Last Access']
  end
end

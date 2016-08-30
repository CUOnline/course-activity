require_relative './test_helper'
require_relative '../helpers/time_helper'

class TimeHelperTest < Minitest::Test
  include TimeHelper

  def test_format_time
    assert_equal('05/18/16 15:30', format_time('2016-05-18T15:30:00Z'))
  end

  def test_first_timestamp_update
    t1 = '2016-05-18T14:30:00Z'
    t2 = '2016-05-18T15:30:00Z'

    data = {'first-access' => t2}
    row = {'First Access' => t1}

    assert_equal t1, first_timestamp(data, row)
  end


  def test_first_timestamp_no_update
    t1 = '2016-05-18T14:30:00Z'
    t2 = '2016-05-18T15:30:00Z'

    data = {'first-access' => t1}
    row = {'First Access' => t2}

    assert_equal "2016-05-18 14:30:00 UTC", first_timestamp(data, row)
  end

  def test_first_timestamp_initial
    t1 = '2016-05-18T14:30:00Z'
    t2 = '2016-05-18T15:30:00Z'

    data = {}
    row = {'First Access' => t1}

    assert_equal t1, first_timestamp(data, row)
  end

  def test_last_timestamp_update
    t1 = '2016-05-18T14:30:00Z'
    t2 = '2016-05-18T15:30:00Z'

    data = {'last-access' => t1}
    row = {'Last Access' => t2}

    assert_equal t2, last_timestamp(data, row)
  end


  def test_last_timestamp_no_update
    t1 = '2016-05-18T14:30:00Z'
    t2 = '2016-05-18T15:30:00Z'

    data = {'last-access' => t2}
    row = {'Last Access' => t1}

    assert_equal "2016-05-18 15:30:00 UTC", last_timestamp(data, row)
  end

  def test_last_timestamp_initial
    t1 = '2016-05-18T14:30:00Z'
    t2 = '2016-05-18T15:30:00Z'

    data = {}
    row = {'Last Access' => t1}

    assert_equal t1, last_timestamp(data, row)
  end

end

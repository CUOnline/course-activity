require_relative './test_helper'
require_relative '../helpers/sort_helper'

class SortHelperTest < Minitest::Test
  include SortHelper

  def test_sort_link
    course_id = 123
    header = 'name'
    sort_by = 'views'

    output = app.new.helpers.sort_link(header, sort_by, course_id)
    expected = "/course-activity/course/#{course_id}?sort=#{header}"
    assert_equal expected, output
  end


  def test_sort_link_flip
    course_id = 123
    header = 'name'
    sort_by = 'name'

    output = app.new.helpers.sort_link(header, sort_by, course_id)
    expected = "/course-activity/course/#{course_id}?sort=#{header}-desc"
    assert_equal expected, output
  end

  def test_sort_class_asc
    expected = 'glyphicon glyphicon-triangle-bottom'
    assert_equal expected, sort_class('name', 'name')
    assert_equal expected, sort_class('views', 'views')
    assert_equal expected, sort_class('participations', 'participations')
  end

  def test_sort_class_desc
    expected = 'glyphicon glyphicon-triangle-top'
    assert_equal expected, sort_class('name', 'name-desc')
    assert_equal expected, sort_class('views', 'views-desc')
    assert_equal expected, sort_class('participations', 'participations-desc')
  end

  def test_sort_class_none
    assert_equal '', sort_class('name', 'views')
    assert_equal '', sort_class('name', 'views-desc')
    assert_equal '', sort_class('views', 'name')
    assert_equal '', sort_class('views-desc', 'name')
    assert_equal '', sort_class('name-desc', 'name')
  end

  def test_sorted_keys
    hash = {
      '1' => {
        'name' => 'b',
        'views' => 3,
        'first-access' => '2016-06-18T15:30:00Z'
      },
      '2' => {
        'name' => 'c',
        'views' => 1,
        'first-access' => '2016-06-18T10:30:00Z'
      },
      '3' => {
        'name' => 'a',
        'views' => 2,
        'first-access' => '2016-05-18T15:30:00Z'
      },
    }

    assert_equal ['1', '2', '3'], sorted_keys(hash, 'not-a-key')
    assert_equal ['3', '1', '2'], sorted_keys(hash, 'name')
    assert_equal ['2', '1', '3'], sorted_keys(hash, 'name-desc')
    assert_equal ['2', '3', '1'], sorted_keys(hash, 'views')
    assert_equal ['3', '2', '1'], sorted_keys(hash, 'first-access')
    assert_equal ['1', '2', '3'], sorted_keys(hash, 'first-access-desc')
  end
end

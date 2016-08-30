require_relative './test_helper'
require_relative '../helpers/data_helper'

class DataHelperTest < Minitest::Test
  include DataHelper
  include TimeHelper

  def test_course_name
    name = 'Course Name'
    app.any_instance.expects(:canvas_data).returns([{'name' => name}])
    output = app.new.helpers.course_name(123)
    assert_equal name, output
  end

  def test_substitute_category
    assert_equal 'Pages', substitute_category('wiki')
    assert_equal 'Discussions', substitute_category('topics')
    assert_equal 'People', substitute_category('roster')
    assert_equal 'Group pages', substitute_category('pages')
    assert_equal 'External tools', substitute_category('external tools')
    assert_equal 'No substitution', substitute_category('no substitution')
  end

  def test_student_data
    row = {
      'Display Name' => 'Student McStudentson',
      'Views' => 10,
      'Participations' => 5,
      'First Access' => '2016-05-18T15:30:00Z',
      'Last Access' => '2016-05-18T17:30:00Z'
    }
    expected = {
      'name' => 'Student McStudentson',
      'views' => 10,
      'participations' => 5,
      'first_access' => '2016-05-18T15:30:00Z',
      'last_access' => '2016-05-18T17:30:00Z'
    }

    assert_equal expected, student_data(row)

    row = {
      'Display Name' => 'Student McStudentson',
      'First Access' => '2016-05-18T15:30:00Z',
      'Last Access' => '2016-05-18T17:30:00Z'
    }
    expected = {
      'name' => 'Student McStudentson',
      'views' => 0,
      'participations' => 0,
      'first_access' => '2016-05-18T15:30:00Z',
      'last_access' => '2016-05-18T17:30:00Z'
    }

    assert_equal expected, student_data(row)
  end

  def test_update_data
    t1 = '2016-05-18T15:30:00Z'
    t2 = '2016-05-18T17:30:00Z'

    data = {
      'views' => 2,
      'participations' => 1,
      'first_access' => '2016-05-18T16:30:00Z',
      'last_access' => '2016-05-18T16:30:00Z'
    }

    row = {
      'Views' => 10,
      'Participations' => 5,
      'First Access' => t1,
      'Last Access' => t2,
    }

    expected = {
      'views' => 12,
      'participations' => 6,
      'first_access' => t1,
      'last_access' => t2,
      'accesses' => {}
    }

    assert_equal expected, update_data(data, row)
  end


  def test_update_data_empty
    t1 = '2016-05-18T15:30:00Z'
    t2 = '2016-05-18T17:30:00Z'

    row = {
      'Views' => 10,
      'Participations' => 5,
      'First Access' => t1,
      'Last Access' => t2,
    }

    expected = {
      'views' => 10,
      'participations' => 5,
      'first_access' => t1,
      'last_access' => t2,
      'accesses' => {}
    }

    assert_equal expected, update_data({}, row)
  end


  def test_update_category_data
    t1 = '2016-05-18T13:30:00Z'
    t2 = '2016-05-18T15:30:00Z'
    t3 = '2016-05-18T17:30:00Z'

    data = {
      'views' => 10,
      'participations' => 5,
      'first_access' => t2,
      'last_access' => t2,
      'accesses' => {
        'wiki_page_1' => {},
        'discussion_topic_2' => {
          'views'=>10,
          'participations'=>5,
          'first_access'=>t2,
          'last_access'=>t2,
          'accesses'=>{
            '123'=>{
              'name'=>'Student McStudentson',
              'views'=>10,
              'participations'=>5,
              'first_access'=>t2,
              'last_access'=>t2
            }
          }
        }
      }
    }

    row = {
      'User ID' => '456',
      'Display Name' => 'Name Namerson',
      'Views' => 3,
      'Participations' => 2,
      'First Access' => t1,
      'Last Access' => t3,
      'Code' => 'discussion_topic_2',
      'Title' => 'Discussion'
    }

    expected = {
      'views'=>13,
      'participations'=>7,
      'first_access'=>t1,
      'last_access'=>t3,
      'accesses'=>{
        'wiki_page_1'=>{},
        'discussion_topic_2'=>{
          'views'=>13,
          'participations'=>7,
          'first_access'=>t1,
          'last_access'=>t3,
          'accesses'=>{
            '123'=>{
              'name'=>'Student McStudentson',
               'views'=>10,
               'participations'=>5,
               'first_access'=>t2,
               'last_access'=>t2
            },
            '456'=>{
              'name'=>'Name Namerson',
              'views'=>3,
              'participations'=>2,
              'first_access'=>t1,
              'last_access'=>t3
            }
          },
          'name'=>'Discussion'
        }
      }
    }
    assert_equal expected, update_category_data(data, row)
  end

  def test_update_item_data
    t1 = '2016-05-18T13:30:00Z'
    t2 = '2016-05-18T15:30:00Z'
    t3 = '2016-05-18T17:30:00Z'

    data = {
      'views'=>10,
      'participations'=>5,
      'first_access'=>t2,
      'last_access'=>t2,
      'accesses'=>{
        '123'=>{
          'name'=>'Student McStudentson',
          'views'=>10,
          'participations'=>5,
          'first_access'=>t2,
          'last_access'=>t2
        }
      }
    }

    row = {
      'User ID' => '456',
      'Display Name' => 'Name Namerson',
      'Views' => 3,
      'Participations' => 2,
      'First Access' => t1,
      'Last Access' => t3,
      'Code' => 'discussion_topic_2',
      'Title' => 'Discussion'
    }

    expected = {
          'views'=>13,
          'participations'=>7,
          'first_access'=>t1,
          'last_access'=>t3,
          'accesses'=>{
            '123'=>{
              'name'=>'Student McStudentson',
               'views'=>10,
               'participations'=>5,
               'first_access'=>t2,
               'last_access'=>t2
            },
            '456'=>{
              'name'=>'Name Namerson',
              'views'=>3,
              'participations'=>2,
              'first_access'=>t1,
              'last_access'=>t3
            }
          },
          'name'=>'Discussion'
        }
    assert_equal expected, update_item_data(data, row)
  end

end

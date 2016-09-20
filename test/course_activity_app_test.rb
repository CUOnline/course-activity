require_relative './test_helper'
require 'minitest/autorun'
require 'minitest/rg'
require 'mocha/mini_test'
require 'rack/test'

class StudentActivityAppTest < Minitest::Test
  def setup
    @tmp_dir = app.respond_to?(:tmp_dir) ? app.send(:tmp_dir) : '/tmp'
    app.set :tmp_dir, @tmp_dir

    @csv_string = "User ID,Display Name,Sortable Name,Category,Class,Title,Views,Participations,Last Access,First Access,Action,Code,Group Code,Context Type,Context ID,Login ID,Section,Section ID,SIS Course ID,SIS Section ID,SIS Login ID,SIS User ID\n1234, Name Namerson,\"Namerson,  Name\",wiki,wiki_page,Wiki Page,1,,2016-05-18T16:34:25Z,2016-05-18T16:34:25Z,view,wiki_page_22222,wiki_33333,Course,111111,222222,Canvas Course,333333,,,444444,555555555\n1235, Student McStudentson,\"McStudentson,  Student\",wiki,wiki_page,Wiki Page,3,,2016-05-20T13:34:25Z,2016-05-21T10:34:25Z,view,wiki_page_22222,wiki_33333,Course,111111,222222,Canvas Course,333333,,,666666,777777777\n1235, Student McStudentson,\"McStudentson,  Student\",quizzes,quizzes/quiz,Final Exam,2,1,2016-06-02T12:11:11Z,2016-06-02T14:11:11Z,participate,quizzes:quiz_22222,quizzes,Course,111111,222222,Canvas Course,333333,,,666666,777777777\n"

    @data_hash = {"Pages":{"views":4,"participations":0,"first_access":"2016-05-21T10:34:25Z","last_access":"2016-05-20T13:34:25Z","accesses":{"wiki_page_22222":{"views":4,"participations":0,"first_access":"2016-05-21T10:34:25Z","last_access":"2016-05-20T13:34:25Z","accesses":{"1234":{"name":" Name Namerson","views":1,"participations":0,"first_access":"2016-05-18T16:34:25Z","last_access":"2016-05-18T16:34:25Z"},"1235":{"name":" Student McStudentson","views":3,"participations":0,"first_access":"2016-05-21T10:34:25Z","last_access":"2016-05-20T13:34:25Z"}},"name":"Wiki Page"}}},"Quizzes":{"views":2,"participations":1,"first_access":"2016-06-02T14:11:11Z","last_access":"2016-06-02T12:11:11Z","accesses":{"quizzes:quiz_22222":{"views":2,"participations":1,"first_access":"2016-06-02T14:11:11Z","last_access":"2016-06-02T12:11:11Z","accesses":{"1235":{"name":" Student McStudentson","views":2,"participations":1,"first_access":"2016-06-02T14:11:11Z","last_access":"2016-06-02T12:11:11Z"}},"name":"Final Exam"}}}}
  end

  def test_get_script
    get '/access-report.js'

    assert_equal 200, last_response.status
    assert_equal 'application/javascript;charset=utf-8', last_response.header['Content-Type']
  end

  def test_get_course
    data = {}
    app.settings.redis.expects(:exists).returns(true)
    app.settings.redis.expects(:get).returns(@data_hash.to_json)

    login
    get '/course/123'

    assert_equal 200, last_response.status
  end

  def test_get_course_no_data
    app.settings.redis.expects(:exists).returns(false)

    login
    get '/course/123'

    assert_equal 200, last_response.status
  end

  def test_get_course_unauthenticated
    get '/course/123'

    assert_equal 302, last_response.status
    follow_redirect!
    assert_equal '/canvas-auth-login', last_request.path
  end

  def test_get_course_unauthorized
    login({'user_roles' => ['StudentEnrollment']})
    get '/course/123'
    assert_equal 302, last_response.status
    follow_redirect!
    assert_equal '/unauthorized', last_request.path
  end

  def test_post_upload_initial
    course_id = '123'
    params = {'courseId' => course_id, 'csvData' => @csv_string}
    app.settings.redis.expects(:exists).with("course:#{course_id}:access_data")
    app.settings.redis.expects(:set).with("course:#{course_id}:csv_data", @csv_string)
    app.settings.redis.expects(:set).with("course:#{course_id}:access_data", @data_hash.to_json)

    post '/upload', params

    assert_equal 200, last_response.status
  end

  def test_post_upload_existing_data
    course_id = '123'
    params = {'courseId' => course_id, 'csvData' => @csv_string}
    app.settings.redis.expects(:exists).with("course:#{course_id}:access_data")
                      .returns(true)

    post '/upload', params

    assert_equal 302, last_response.status
  end

  def test_post_upload_invalid_csv
    course_id = '123'
    params = {'courseId' => course_id, 'csvData' => "Category,Views\ndata, \"data2\n"}
    app.settings.redis.expects(:exists).with("course:#{course_id}:access_data")
                                        .returns(false)

    post '/upload', params

    assert_equal 400, last_response.status
    assert_equal 'Invalid CSV data provided', last_response.body
  end

  def test_get_check_data_true
    course_id = 123
    app.redis.expects(:exists).with("course:#{course_id}:access_data").returns(true)

    get "/check-data/#{course_id}"

    assert_equal 200, last_response.status
    assert_equal '1', last_response.body
  end


  def test_get_check_data_false
    course_id = 123
    app.redis.expects(:exists).with("course:#{course_id}:access_data").returns(false)

    get "/check-data/#{course_id}"

    assert_equal 200, last_response.status
    assert_equal '', last_response.body
  end

  def test_post_reload
    course_id = 123
    csv_file = File.join(@tmp_dir, "access_data_#{course_id}.csv")
    File.open(csv_file, 'w')
    assert File.exists?(csv_file)
    app.redis.expects(:del).with("course:#{course_id}:access_data")
    app.redis.expects(:del).with("course:#{course_id}:csv_data")

    login
    post '/reload', {:course_id => course_id}

    assert_equal 200, last_response.status
    assert_match /Data for this course has been reset/, last_response.body
    assert !File.exists?(csv_file)
  end

  def test_post_reload_unauthenticated
    post '/reload/123'

    assert_equal 302, last_response.status
    follow_redirect!
    assert_equal '/canvas-auth-login', last_request.path
  end

  def test_post_reload_unauthorized
    login({'user_roles' => ['StudentEnrollment']})
    post '/reload/123'
    assert_equal 302, last_response.status
    follow_redirect!
    assert_equal '/unauthorized', last_request.path
  end

  def test_get_download_no_data
    course_id = 123
    app.redis.expects(:exists).with("course:#{course_id}:csv_data").returns(false)

    login
    get "/download/#{course_id}"

    assert_equal 200, last_response.status
    assert_match /course does not have any uploaded data/, last_response.body
  end

  def test_get_download_with_data
    course_id = 123
    csv_file = File.join(@tmp_dir, "access_data_#{course_id}.csv")
    assert !File.exists?(csv_file)
    app.redis.expects(:exists).with("course:#{course_id}:csv_data").returns(true)
    app.redis.expects(:get).with("course:#{course_id}:csv_data").returns(@csv_string)

    login
    get "/download/#{course_id}"

    assert File.exists?(csv_file)
    assert_equal 200, last_response.status
    assert_equal 'text/csv;charset=utf-8', last_response.header['Content-Type']
    assert_equal File.read(csv_file), @csv_string

    File.delete(csv_file)
  end

  def test_get_download_unauthenticated
    get '/download/123'

    assert_equal 302, last_response.status
    follow_redirect!
    assert_equal '/canvas-auth-login', last_request.path
  end

  def test_get_download_unauthorized
    login({'user_roles' => ['StudentEnrollment']})
    get '/download/123'
    assert_equal 302, last_response.status
    follow_redirect!
    assert_equal '/unauthorized', last_request.path
  end
end

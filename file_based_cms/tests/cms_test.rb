ENV['RACK_ENV'] = 'test'

require 'minitest/reporters'
Minitest::Reporters.use!

require 'minitest/autorun'
require 'rack/test'
require 'fileutils'

require 'pry'
require_relative('../cms')

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    FileUtils::mkdir_p(data_path)
  end

  def teardown
    FileUtils::rm_rf(data_path)
  end

  def test_index
    create_document('about.md')
    create_document('changes.txt')

    get '/'

    assert_equal(200, last_response.status)
    assert_equal('text/html;charset=utf-8', last_response['Content-Type'])
    assert_includes(last_response.body, 'about.md')
    assert_includes(last_response.body, 'changes.txt')
  end

  def test_view_file
    skip
    get '/history.txt'

    latest_release = "2022 - Ruby 3.2 released."

    assert_equal(200, last_response.status)
    assert_equal('text/plain', last_response['Content-Type'])
    assert_includes(last_response.body, latest_release)
  end

  def test_view_nonexistent_file
    skip
    bad_file = 'bad_file.txt'
    
    get "/#{bad_file}"
    assert_equal(302, last_response.status)

    get last_response['Location']
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "#{bad_file} does not exist.")

    # Reload
    get '/'
    refute_includes(last_response.body, "#{bad_file} does not exist.")
  end

  def test_markdown_render
    skip
    md_file = 'about.md'

    get "/#{md_file}"

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "<h1>README.md</h1>")
  end

  def test_file_edit_form
    skip
    get '/changes.txt/edit'

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "<textarea")
    assert_includes(last_response.body, '<button type="submit"')
  end

  def test_file_editing
    skip
    post '/changes.txt', content: "Edited Contents!"

    # Redirects
    assert_equal(302, last_response.status)
    get last_response['Location']
    # Prints message
    assert_includes(last_response.body, 'changes.txt has been updated.')

    get '/changes.txt'
    # Contents change
    assert_includes(last_response.body, 'Edited Contents!')
    # Message disappears
    refute_includes(last_response.body, 'changes.txt has been updated.')
  end

  # # # # # # 
  # Helpers #
  # # # # # #
  def create_document(name, content="")
    File.open(File.join(data_path, name), 'w') do |file|
      file.write(content)
    end
  end
end


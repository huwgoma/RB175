ENV['RACK_ENV'] = 'test'

require 'minitest/reporters'
Minitest::Reporters.use!

require 'minitest/autorun'
require 'rack/test'

require_relative('../cms')

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_index
    get '/'

    file_names = ["about.md", "changes.txt", "history.txt"]

    assert_equal(200, last_response.status)
    assert_equal('text/html;charset=utf-8', last_response['Content-Type'])
    file_names.each { |name| assert_includes(last_response.body, name) }
  end

  def test_view_file
    get '/history.txt'

    latest_release = "2022 - Ruby 3.2 released."

    assert_equal(200, last_response.status)
    assert_equal('text/plain', last_response['Content-Type'])
    assert_includes(last_response.body, latest_release)
  end

  def test_view_nonexistent_file
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
    md_file = 'about.md'

    get "/#{md_file}"

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "<h1>README.md</h1>")
  end
end


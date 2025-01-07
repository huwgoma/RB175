ENV['RACK_ENV'] = 'test'

require 'minitest/reporters'
Minitest::Reporters.use!

require 'minitest/autorun'
require 'rack/test'
require 'fileutils'
require 'yaml'
require_relative('../cms') 

require 'pry'



class CMSTest < Minitest::Test
  include Rack::Test::Methods

  CONTENTS = YAML.load_file(File.expand_path("../contents.yml", data_path))
  
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
    create_document('history.txt', CONTENTS['history'])

    get '/history.txt'

    assert_equal(200, last_response.status)
    assert_equal('text/plain', last_response['Content-Type'])
    assert_includes(last_response.body, "2022 - Ruby 3.2 released.")
  end

  def test_view_nonexistent_file
    bad_file = 'bad_file.txt'
    
    get "/#{bad_file}"
    assert_equal(302, last_response.status)

    get last_response['Location']
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "#{bad_file} does not exist.")

    # Message disappears upon reload
    get '/'
    refute_includes(last_response.body, "#{bad_file} does not exist.")
  end

  def test_markdown_render
    create_document('about.md', CONTENTS['about'])

    get "/about.md"

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "<h1>README.md</h1>")
  end

  def test_file_edit_form
    create_document('changes.txt', CONTENTS['changes'])

    get '/changes.txt/edit'

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "<textarea")
    assert_includes(last_response.body, 'This is a changelog.')
  end

  def test_file_editing
    create_document('changes.txt', CONTENTS['changes'])

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

  def test_new_file_form
    get '/new'

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, '<form action="/new" method="post">')
  end

  def test_successful_file_creation
    post '/new', file_name: "new_file.txt"
    assert_equal(302, last_response.status)

    get last_response['Location']
    assert_includes(last_response.body, "new_file.txt was created.")
    assert_includes(last_response.body, '<a href="/new_file.txt">')
  end

  def test_bad_file_creation
    post '/new', file_name: ''
    assert_includes(last_response.body, 'File name cannot be blank.')
    
    post '/new', file_name: "no_ext"
    assert_includes(last_response.body, 'File extension cannot be blank.')

    create_document('changes.txt')
    post '/new', file_name: 'changes.txt'
    assert_includes(last_response.body, 'That file already exists.')
  end

  def test_file_deletion
    create_document('disposable.txt')
    post '/disposable.txt/delete'

    assert_equal(302, last_response.status)
    get last_response['Location']
    assert_includes(last_response.body, 'disposable.txt has been deleted.')
    refute_includes(last_response.body, '<a href="/disposable.txt">')
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


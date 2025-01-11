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

  CONTENTS = YAML.load_file(File.join(root_path, 'tests', 'contents.yml'))
  
  def app
    Sinatra::Application
  end

  def setup
    FileUtils::mkdir_p(data_path)
    # Create users.yml and populate it with admin: secret (h)
  end

  def teardown
    FileUtils::rm_rf(data_path)
    # FileUtils::rm_rf(users_path)
  end

  def test_index
    files = ['about.md', 'changes.txt']
    files.each { |filename| create_document(filename) }

    get '/'

    assert_equal(200, last_response.status)
    assert_equal('text/html;charset=utf-8', last_response['Content-Type'])
    files.each { |filename| assert_includes(last_response.body, filename) }
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
    assert_equal("#{bad_file} does not exist.", session[:message])

    # session[:message] is deleted on the next request.
    get '/'
    assert_nil(session[:message])
  end

  def test_markdown_render
    create_document('about.md', CONTENTS['about'])

    get "/about.md"

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "<h1>README.md</h1>")
  end

  def test_file_edit_form
    create_document('changes.txt', CONTENTS['changes'])

    get '/changes.txt/edit', {}, login_session

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "<textarea")
    assert_includes(last_response.body, 'This is a changelog.')
  end

  def test_file_editing
    create_document('changes.txt', CONTENTS['changes'])

    post '/changes.txt', { content: "Edited Contents!" }, login_session

    # Sets message and redirects 
    assert_equal(302, last_response.status)
    assert_equal('changes.txt has been updated.', session[:message])
    # Follow redirect
    get last_response['Location']

    # View file again
    get '/changes.txt'
    assert_includes(last_response.body, 'Edited Contents!')
    assert_nil(session[:message])
  end

  def test_new_file_form
    get '/new', {}, login_session

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, '<form action="/new" method="post">')
  end

  def test_successful_file_creation
    post '/new', { file_name: "new_file.txt" }, login_session

    assert_equal(302, last_response.status)
    assert_equal("new_file.txt was created.", session[:message])
    # Follow redirect to home
    get last_response['Location']
    assert_includes(last_response.body, '<a href="/new_file.txt">')
  end

  def test_bad_file_creation
    post '/new', { file_name: '' }, login_session
    assert_includes(last_response.body, 'File name cannot be blank.')
    
    post '/new', file_name: "no_ext"
    assert_includes(last_response.body, 'File extension cannot be blank.')

    post '/new', file_name: "bad_ext.ext"
    assert_includes(last_response.body, 'Only .txt or .md files are supported.')

    create_document('changes.txt')
    post '/new', file_name: 'changes.txt'
    assert_includes(last_response.body, 'That file already exists.')
  end

  def test_file_duplication
    create_document('test.txt', 'Hello World!')
    post '/test.txt/duplicate', {}, login_session
    assert_equal('copy_of_test.txt was created.', session[:message])

    get last_response['Location']
    assert_includes(last_response.body, 'copy_of_test.txt')
  end

  def test_md_file_duplication
    create_document('test.md', '# Heading 1')
    post '/test.md/duplicate', {}, login_session

    assert_equal('copy_of_test.md was created.', session[:message])

    get last_response['Location']
    assert_includes(last_response.body, 'copy_of_test.md')

    get '/copy_of_test.md/edit'
    assert_includes(last_response.body, '# Heading 1')
  end

  def test_file_deletion
    create_document('disposable.txt')
    post '/disposable.txt/delete', {}, login_session

    assert_equal(302, last_response.status)
    assert_equal('disposable.txt has been deleted.', session[:message])
    
    get last_response['Location']
    refute_includes(last_response.body, '<a href="/disposable.txt">')
  end

  # # # # #
  # Users #
  # # # # #
  def test_good_user_registration
    post '/users/new', username: 'user', password: 'good_password'

    assert_includes(session[:message], 'Welcome!')
    assert_equal(302, last_response.status)

    post '/users/login', username: 'user', password: 'good_password'
    
    assert_equal(true, session[:logged_in])
     
    #
    # User is signed out.
    # User submits a good user/password combo
    # message is set
    # follow redirect to login page
    # login with user/password combo
    # session[Logged in] should be true
  end

  def test_login_form
    # Redirects users if logged in
    get '/users/login', {}, login_session
    assert_equal(302, last_response.status)
    
    # Displays form if not logged in
    get '/users/login', {}, { 'rack.session' => { logged_in: false } }
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, '<form action="/users/login" method="post">')
  end
  
  def test_good_login
    post '/users/login', username: 'admin', password: 'secret'
    
    assert_equal('Welcome!', session[:message])
    assert_equal('admin', session[:username])
    assert_equal(true, session[:logged_in])
    assert_equal(302, last_response.status)
    
    get last_response['Location']
    assert_includes(last_response.body, 'Signed in as admin.')
  end

  def test_bad_login
    post '/users/login', username: 'admin', password: 'incorrect'

    # Bad logins render the login form ERB template, which results in 
    # session[:message] being deleted within the same request. Therefore
    # session[:message] is nil here bc it was already deleted during the request.
    assert_includes(last_response.body, 'Invalid login credentials.')
    # Re-renders the login form
    assert_includes(last_response.body, '<form action="/users/login" method="post">')
    # Username value is autofilled
    assert_includes(last_response.body, 'admin')
  end

  def test_logout
    # Log in
    post '/users/login', {}, login_session

    post '/users/logout'
    assert_equal(302, last_response.status)
    assert_equal(false, session[:logged_in])
    assert_nil(session[:username])
    assert_equal('You have been logged out.', session[:message])
  end

  # Login Restrictions
  def test_restrict_create_view_access
    get '/new'
    assert_equal('You must be logged in to do that.', session[:message])
    assert_equal(302, last_response.status)
  end

  def test_restrict_create_submit_access
    post '/new'
    assert_equal('You must be logged in to do that.', session[:message])
    assert_equal(302, last_response.status)
  end

  def test_restrict_edit_view_access
    create_document('file.txt')
    
    get '/file.txt/edit'
    assert_equal('You must be logged in to do that.', session[:message])
    assert_equal(302, last_response.status)
  end

  def test_restrict_edit_submit_access
    create_document('file.txt')
    
    post '/file.txt'
    assert_equal('You must be logged in to do that.', session[:message])
    assert_equal(302, last_response.status)
  end

  def test_restrict_delete_access
    create_document('file.txt')
    
    post '/file.txt/delete'
    assert_equal('You must be logged in to do that.', session[:message])
    assert_equal(302, last_response.status)
  end

  # # # # # # 
  # Helpers #
  # # # # # #
  def session
    last_request.env['rack.session']
  end

  def create_document(name, content="")
    File.open(File.join(data_path, name), 'w') do |file|
      file.write(content)
    end
  end

  def login_session
    { 'rack.session' => { username: 'admin', logged_in: true }}
  end
end


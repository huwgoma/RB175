require 'sinatra'
require 'redcarpet'

if development?
  require 'sinatra/reloader'
  require 'pry'
end

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)  
end

before do

end

helpers do
  def logged_in?
    session[:logged_in]
  end
end
# Signing in and out:
# 1) When a signed-out user views the index page, they should see a sign in link:
# [Sign In]    
#  => Routes to GET /users/signin
#  
# 2) The signin page contains a form with 3 elements:
# [Username]
# [Password]
# [Sign In]
#  => Submits to POST /users/signin
#  
# 3) POST /users/signin
#  - Verify the given params[:username] and params[:password]
#    - If credentials are valid (username == 'admin' and password == 'secret'),
#      set a session message ('Welcome!') and redirect the user to the index page.
#      - In addition, store the following in the session: 
#        - username
#        - signed_in = true

#    - If credentials are invalid, set a session message ('Invalid credentials')
#      and re-render the signin form.
#      - username value should be params[:username] (the previously-entered value)
#      
# 4) GET /
#    - If the user is not signed in, display the login page.
#    - If the user is signed in, display the files page as normal.
#      - Also add a link at the bottom:
#      Signed in as <USERNAME>. [Sign Out]
#                                => Submits to POST /users/logout
# 5) POST /users/logout
#    - Delete the username from the session
#    - Set session[logged_in] to false
#    - Set a session message ('You have been signed out.')
#    - Redirect to index (/)



# # # # # # 
# Routes  #
# # # # # # 

# User login form
get '/users/login' do
  redirect '/' if logged_in?
  erb :login  
end

# User login
post '/users/login' do
  if valid_login?(params[:username], params[:password])
    session[:message] = 'Welcome!'
    session[:username] = params[:username]
    session[:logged_in] = true
    redirect '/'
  else
    session[:message] = 'Invalid login credentials.'
    erb :login
  end
end

post '/users/logout' do
  session.delete(:username)
  session[:logged_in] = false
  session[:message] = 'You have been logged out.'
  
  redirect '/'
end

def valid_login?(username, password)
  username == 'admin' && password == 'secret'
end

# Home Page - Display all files
get '/' do
  @file_names = Dir.glob("#{data_path}/*").map { |path| File.basename(path) }
  @username = session[:username]

  erb :index
end

# Form to create new files 
get '/new' do
  erb :new_file
end

# Create a new file
post '/new' do
  file_name = params[:file_name].strip

  error = file_creation_error(file_name)
  if error
    session[:message] = error
    erb :new_file
  else
    create_file(file_name)
    session[:message] = "#{file_name} was created."
    redirect '/'
  end
end

# Retrieve and display a specific file
get '/:file_name' do
  file_name = params[:file_name]
  file_path = File.join(data_path, file_name)
  
  headers['Content-Type'] = cont_type(file_path)
  load_file(file_path)
end

# Retrieve the form page for editing a file
get '/:file_name/edit' do
  @file_name = params[:file_name]
  file_path = File.join(data_path, @file_name)
  
  @file = load_file(file_path, format: false)
  # Escape HTML?
  erb :edit_file
end

# Edit the contents of a file
post '/:file_name' do
  file_name = params[:file_name]
  file_path = File.join(data_path, file_name)

  File.open(file_path, 'w') do |file|
    file.write(params[:content])
  end

  session[:message] = "#{file_name} has been updated."
  redirect '/'
end

# Delete a document
post '/:file_name/delete' do
  file_name = params[:file_name]
  file_path = File.join(data_path, file_name)
  
  File.delete(file_path)

  session[:message] = "#{file_name} has been deleted."
  redirect '/'
end

# # # # # # 
# Helpers #
# # # # # #
def data_path
  if ENV['RACK_ENV'] == 'test'
    File.expand_path("../tests/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def load_file(path, format: true)
  if File.exist?(path)
    format ? format_file(path) : File.read(path)
  else
    session[:message] = "#{File.basename(path)} does not exist."
    redirect '/'
  end
end

def format_file(path)
  file = File.read(path)

  case File.extname(path)
  when '.txt'
    file
  when '.md'
    erb markdown_to_html(file)
  end
end

def cont_type(path)
  case File.extname(path)
  when '.txt'
    'text/plain'
  else 
    'text/html'
  end
end

def file_creation_error(name)
  if name.empty?
    'File name cannot be blank.'
  elsif File.extname(name).empty?
    'File extension cannot be blank.'
  elsif File.exist?(File.join(data_path, name))
    'That file already exists.'
  end
end

def create_file(name)
  File.new(File.join(data_path, name), 'w')
end

def markdown_to_html(string)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(string)
end
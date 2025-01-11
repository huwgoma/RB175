require 'sinatra'
require 'redcarpet'
require 'yaml'
require 'bcrypt'

require 'sinatra/reloader' if development?
require 'pry' if development?

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)  
end

helpers do
  def logged_in?
    session[:logged_in]
  end
end

# Additional Features:

# 2) Duplicate File - Create a new document with the same contents as an 
#    existing one 
#   - On the new document view?
#   Create a new document: [      ]
#   Or, duplicate an existing one:
#   > about.md
#   > changes.txt
#   -> When clicked:
#   - Create a new file with the name copy_of_filename, and the
#     contents of filename
#   - Redirect to homepage
#   
#   - Most of this ^ functionality is identical to POST /new
#     - The only real difference is that we are attaching 
#       copy_of_ to the file name, and copying the contents over
#
#
# 3) User Signup Form - Allow users to create new accounts
# 4) Allow images to be added to the CMS (wrapped within .md files; ![text][path/to/img])
# 5) Preserve each document version as changes are made.

# # # # # # 
# Routes  #
# # # # # # 
# Home Page - Display all files
get '/' do
  @file_names = load_file_names
  @username = session[:username] if logged_in?

  erb :index
end

# Form to create new files 
get '/new' do
  verify_login_status

  @file_names = load_file_names
  erb :new_file
end

# Create a new file
post '/new' do
  verify_login_status

  file_name = params[:file_name].strip
  error = file_creation_error(file_name)

  if error
    session[:message] = error
    @file_names = load_file_names
    erb :new_file
  else
    create_file(file_name)
    session[:message] = "#{file_name} was created."
    redirect '/'
  end
end

# Duplicate a file
post '/:file_name/duplicate' do
  verify_login_status

  original_contents = load_file(File.join(data_path, params[:file_name]))
  copy_file_name = "copy_of_#{params[:file_name]}"
  create_file(copy_file_name, original_contents)
  
  session[:message] = "#{copy_file_name} was created."
  redirect '/'
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
  verify_login_status

  @file_name = params[:file_name]
  file_path = File.join(data_path, @file_name)
  
  @file = load_file(file_path, format: false)
  # Escape HTML?
  erb :edit_file
end

# Edit the contents of a file
post '/:file_name' do
  verify_login_status

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
  verify_login_status
  
  file_name = params[:file_name]
  file_path = File.join(data_path, file_name)
  
  File.delete(file_path)

  session[:message] = "#{file_name} has been deleted."
  redirect '/'
end

# # # # # # # # 
# User Logins # 
# # # # # # # #
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

# Log out
post '/users/logout' do
  session.delete(:username)
  session[:logged_in] = false
  session[:message] = 'You have been logged out.'
  
  redirect '/'
end

# # # # # # 
# Helpers #
# # # # # #
def root_path
  File.expand_path("..", __FILE__)  
end

def data_path
  if ENV['RACK_ENV'] == 'test'
    File.expand_path("../tests/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def load_file_names
  Dir.glob("#{data_path}/*").map { |path| File.basename(path) }
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
  elsif !supported_extnames.include?(File.extname(name))
    "Only #{joinor(supported_extnames, ' or ')} files are supported."
  elsif File.exist?(File.join(data_path, name))
    'That file already exists.'
  end
end

def supported_extnames
  ['.txt', '.md']
end

def joinor(array, separator=" ")
  case 
  when array.size <= 2
    array.join(separator)
  when array.size >= 3
    "#{array[0..-2].join(', ')}, #{separator.strip} #{array[-1]}"
  end
end

def create_file(name, contents="")
  File.open(File.join(data_path, name), 'w') do |file|
    file.write(contents)
  end
end

def markdown_to_html(string)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(string)
end

def valid_login?(username, password)
  credentials = load_user_credentials
  return false unless credentials.has_key?(username)

  bcrypt_password = BCrypt::Password.new(credentials[username])
  bcrypt_password == password
end

def load_user_credentials
  users_path = if ENV['RACK_ENV'] == 'test'
    File.join(root_path, 'tests', 'users.yml')
  else
    File.join(root_path, 'users.yml')
  end

  YAML.load_file(users_path)
end

def verify_login_status
  prevent_access unless logged_in?
end

def prevent_access
  session[:message] = "You must be logged in to do that."
  redirect '/'
end


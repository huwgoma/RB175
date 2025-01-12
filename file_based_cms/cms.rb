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
# 4) Allow images in the CMS
# - 
#

#
#
#
#
#
#
# 4) Allow images to be added to the CMS (wrapped within .md files; ![text][path/to/img])
# 5) Preserve each document version as changes are made.

#########################################  
#                Routes                 #
#########################################
# # # # # # # 
#   Files   #
# # # # # # #
# Home Page - Display all files
get '/' do
  @file_names = load_file_names
  @username = session[:username] if logged_in?

  erb :index
end

# Form for creating files 
get '/new' do
  verify_login_status

  @file_names = load_file_names
  erb :new_file
end

# Create a file
post '/new' do
  verify_login_status

  file_name = params[:file_name].strip
  session[:message] = file_creation_error(file_name)

  if session[:message]
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

  original_contents = load_file(File.join(data_path, params[:file_name]), format: false)
  copy_file_name = "copy_of_#{params[:file_name]}"
  create_file(copy_file_name, original_contents)
  
  session[:message] = "#{copy_file_name} was created."
  redirect '/'
end

# Read a file
get '/:file_name' do
  file_name = params[:file_name]
  file_path = File.join(data_path, file_name)
  
  headers['Content-Type'] = cont_type(file_path)
  load_file(file_path)
end

# Form for editing files 
get '/:file_name/edit' do
  verify_login_status

  @file_name = params[:file_name]
  file_path = File.join(data_path, @file_name)
  
  @file = load_file(file_path, format: false)
  # Escape HTML?
  erb :edit_file
end

# Edit a file
post '/:file_name' do
  verify_login_status

  file_name = params[:file_name]
  file_path = File.join(data_path, file_name)

  write_to_file(file_path, params[:content])

  session[:message] = "#{file_name} has been updated."
  redirect '/'
end

# Delete a file
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

# Form for creating new users
get '/users/new' do
  redirect '/' if logged_in?

  erb :new_user
end

# Create a new user
post '/users/new' do
  username, password = params[:username], params[:password]
  session[:message] = user_creation_error(username, password)

  if session[:message]
    erb :new_user
  else
    add_user_credentials(username, password)

    session[:message] = 'Welcome! Please enter your username and password.'
    redirect '/users/login'
  end
end

# User login form
get '/users/login' do
  redirect '/' if logged_in?

  erb :login  
end

# User login
post '/users/login' do
  username, password = params[:username], params[:password]

  if valid_login?(username, password)
    set_login_session(username)
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

#########################################  
#               Helpers                 #
#########################################

# # # # # 
# Files #
# # # # # 
# Pathfinding
def root_path
  File.expand_path("..", __FILE__)  
end

def data_path
  if ENV['RACK_ENV'] == 'test'
    File.join(root_path, 'tests', 'data')
  else
    File.join(root_path, 'data')
  end
end

def users_path
  if ENV['RACK_ENV'] == 'test'
    File.join(root_path, 'tests', 'users.yml')
  else
    File.join(root_path, 'users.yml')
  end
end

# Loading
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

def load_user_credentials
  YAML.load_file(users_path)
end

def load_file_names
  Dir.glob("#{data_path}/*").map { |path| File.basename(path) }
end

def cont_type(path)
  case File.extname(path)
  when '.txt'
    'text/plain'
  else 
    'text/html'
  end
end

# Writing
def write_to_file(path, contents='')
  File.open(path, 'w') { |file| file.write(contents) }
end

def create_file(name, contents="")
  write_to_file(File.join(data_path, name), contents)
end

def add_user_credentials(username, password)
  credentials = load_user_credentials
  hashed_password = bcrypt_hash(password)

  credentials[username] = hashed_password

  write_to_file(users_path, credentials.to_yaml)
end

# Validation
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

# # # # # # # # # # 
# User & Sessions # 
# # # # # # # # # #
def user_creation_error(username, password)
  if [username, password].map(&:strip).any?(&:empty?) 
    'Username and password cannot be blank.'
  elsif load_user_credentials.has_key?(username)
    'Sorry, that username is already taken.'
  end
end

def verify_login_status
  prevent_access unless logged_in?
end

def prevent_access
  session[:message] = "You must be logged in to do that."
  redirect '/'
end

def valid_login?(username, password)
  credentials = load_user_credentials
  
  BCrypt::Password.new(credentials[username]) == password
end

def set_login_session(username)
  session[:message] = 'Welcome!'
  session[:username] = username
  session[:logged_in] = true
end

def bcrypt_hash(password)
  BCrypt::Password.create(password).to_s
end

# # # # # 
# Misc. # 
# # # # #
def markdown_to_html(string)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(string)
end

def joinor(array, separator=" ")
  case 
  when array.size <= 2
    array.join(separator)
  when array.size >= 3
    "#{array[0..-2].join(', ')}, #{separator.strip} #{array[-1]}"
  end
end
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

# # # # # # 
# Routes  #
# # # # # # 
# Home Page - Display all files
get '/' do
  @file_names = Dir.glob("#{data_path}/*").map do |path|
    File.basename(path)
  end

  erb :files
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


# New Document
# 1) When the user views the index page, they should see a "new doc" link
#   => files.erb - new doc link, links to GET '/new'
#    
# 2) When the user clicks on new doc, they should see a page for creating a new doc:
#   - Add a new document => Input field => Create
#   => GET '/new'
# 3) Clicking Create should submit a POST request:
#   => POST '/new'
#     Validations:
#     - If name is empty => "Document name cannot be blank"
#   => Re-render: erb :new_file
# 4) If everything is valid, create a new document
#   => New file with the given name at data_path/
#     - If the document does not have an extension, default to txt
#   => Set success message.
#   => Redirect the user to index (home) after successful creation


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
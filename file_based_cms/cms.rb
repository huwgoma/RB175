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
  @root = File.expand_path("..", __FILE__)
end

# Home Page - Display all files
get '/' do
  @file_names = Dir.children("#{@root}/data")

  erb :files
end

# Retrieve and display a specific file
get '/:file_name' do
  file_name = params[:file_name]
  file_path = "#{@root}/data/#{file_name}"
  
  if File.exist?(file_path)
    headers['Content-Type'] = file_type(file_path)
    load_file(file_path)
  else
    session[:message] = "#{file_name} does not exist."
    redirect '/' 
  end
end

# Retrieve the form page for editing a file
get '/:file_name/edit' do
  @file_name = params[:file_name]
  file_path = "#{@root}/data/#{@file_name}"

  @file = File.read(file_path)

  erb :edit_file
end

# Edit the contents of a file
post '/:file_name' do
  file_name = params[:file_name]
  file_path = "#{@root}/data/#{file_name}"

  File.open(file_path, 'w') do |file|
    file.write(params[:content])
  end

  session[:message] = "#{file_name} has been updated."
  redirect '/'
end

# # # # # # 
# Helpers #
# # # # # #
def load_file(path)
  file = File.read(path)

  case File.extname(path)
  when '.txt'
    file
  when '.md'
    markdown_to_html(file)
  end
end

def file_type(path)
  case File.extname(path)
  when '.txt'
    'text/plain'
  else 
    'text/html'
  end
end

def markdown_to_html(string)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(string)
end
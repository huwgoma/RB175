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

get '/' do
  @file_names = Dir.children("#{@root}/data")

  erb :files
end

get '/:file_name' do
  file_name = params[:file_name]
  file_path = "#{@root}/data/#{file_name}"
  
  if File.exist?(file_path)
    load_file(file_path)
  else
    session[:error] = "#{file_name} does not exist."
    redirect '/' 
  end
end


# # # # # # 
# Helpers #
# # # # # #
def load_file(path)
  file = File.read(path)

  case File.extname(path)
  when '.txt'
    headers['Content-Type'] = 'text/plain'
    file
  when '.md'
    markdown_to_html(file)
  end
end

def markdown_to_html(string)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(string)
end
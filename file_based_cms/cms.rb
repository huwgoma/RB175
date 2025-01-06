require 'sinatra'

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

  unless File.exist?(file_path)
    session[:error] = "#{file_name} does not exist."
    redirect '/' 
  end

  headers['Content-Type'] = 'text/plain'
  @file = File.read(file_path)
end
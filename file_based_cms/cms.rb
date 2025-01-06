require 'sinatra'

if development?
  require 'sinatra/reloader'
  require 'pry'
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
  
  headers['Content-Type'] = 'text/plain'
  @file = File.read(file_path)
  # Render contents of file
  # (Direct serving? - only for public?)
end
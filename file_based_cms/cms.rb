require 'sinatra'

if development?
  require 'sinatra/reloader'
  require 'pry'
end

before do
  
end

get '/' do
  app_root = File.expand_path("..", __FILE__)
  @file_names = Dir.children("#{app_root}/data")
  
  erb :files
end

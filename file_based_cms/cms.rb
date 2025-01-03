require 'sinatra'

if development?
  require 'sinatra/reloader'
  require 'pry'
end

before do
  
end

get '/' do
  @filenames = Dir.children('data')

  erb :files
  
  # List all files in the CMS:
  # history.txt, changes.txt, about.txt
  # 1) Create files - where? ( data?)
  # 2) Create views (views/layout.erb, views/files.erb)
  # 3) - Load all filenames from data/ into @filenamess
  # 4) Render files.erb
  # # - Iterate through @files and create a <li> for each
  
end

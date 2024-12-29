# app.rb
require 'sinatra'
require 'sinatra/contrib'
require 'sinatra/reloader'
require 'tilt/erubis'

configure do
  set :erb, :escape_html => true
end

get '/' do
  erb :template
end

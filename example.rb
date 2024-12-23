# app.rb
require 'sinatra'
require 'sinatra/contrib'

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/contrib'
require 'tilt/erubis'

# Render the new user form
get '/users/new' do
  erb :new_user_form
end

# app.rb

# Create a new user
post '/users' do
  # ...
  if errors.any? # [<errors>]
    session[:error] = errors.join("\n")
    erb :new_user_form
  else
    session[:success] = "New user created!"
    redirect "/users/#{user.id}"
  end
end



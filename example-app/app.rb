require 'sinatra'
require 'sinatra/reloader'

configure do
  set :erb, :escape_html => false
end

get '/' do
  erb :layout
end

# app.rb
post '/lists/:list_id/todos/:todo_id/delete' do
  if env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest'
    # Return a status code for the client-side 
    # JavaScript to use.
  else 
    # ...
  end
end


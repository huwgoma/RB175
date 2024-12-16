# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/contrib'
require 'tilt/erubis'

require 'pry'

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

before do
  session[:lists] ||= []
end

get '/' do
  redirect '/lists'
end

# Lists
# View all lists
get '/lists' do
  @lists = session[:lists]

  erb :lists
end

# Render new list form
get '/lists/new' do
  erb :new_list
end

# Create new list object
post '/lists' do
  list_name = params[:list_name].strip

  session[:error] = list_name_error(list_name)

  if session[:error]
    erb :new_list
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = 'List successfully created.'
    redirect '/lists'
  end
end

# Display a specific list object
get '/lists/:id' do
  redirect '/lists' unless valid_list_id?(params[:id])

  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  
  erb :list
end

# Form for editing existing list
get '/lists/:id/edit' do
  redirect '/lists' unless valid_list_id?(params[:id])

  @list_id = params[:id].to_i

  @list = session[:lists][@list_id]

  erb :edit_list
end

# Update existing list
post '/lists/:id' do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]

  list_name = params[:list_name].strip
  
  session[:error] = list_name_error(list_name)

  if session[:error]
    erb :list
  else
    @list[:name] = list_name
    session[:success] = 'List successfully updated.'
    redirect "/lists/#{@list_id}"
  end
end

# Delete a list
post '/lists/:id/delete' do
  session[:lists].delete_at(params[:id].to_i)
  session[:success] = 'List successfully deleted.'

  redirect '/lists'
end

# To-Dos
# Add a new to-do to a list
post '/lists/:list_id/todos' do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]

  todo = params[:todo].strip

  session[:error] = todo_error(todo)

  if session[:error]
    erb :list
  else
    @list[:todos] << { name: todo, completed: false }

    session[:success] = 'To-do successfully added.'
    redirect "/lists/#{@list_id}"
  end  
end

# Delete a to-do from a list
post '/lists/:list_id/todos/:todo_id/delete' do
  list_id = params[:list_id].to_i
  list = session[:lists][list_id]

  list[:todos].delete_at(params[:todo_id].to_i)
  session[:success] = 'To-do successfully deleted.'
  redirect "/lists/#{list_id}"
end

# Mark a specific to-do as complete
post '/lists/:list_id/todos/:todo_id/complete' do
  list_id = params[:list_id].to_i
  todo_id = params[:todo_id].to_i
  list = session[:lists][list_id]
  todo = list[:todos][todo_id]

  todo[:completed] = true?(params[:completed])
  session[:success] = 'To-do successfully updated.'
  redirect "/lists/#{list_id}"
end

# Helpers
def valid_list_id?(id)
  integer?(id) && session[:lists].fetch(id.to_i, false)
end

def integer?(string)
  string == string.to_i.to_s
end

def true?(obj)
  obj.to_s == 'true'
end

# Validate names (list/todos) 
# - Return a custom error string if name is invalid, or nil
#   if the name is valid.
def list_name_error(name)
  if session[:lists].any? { |list| list[:name] == name }
    'That list already exists.'
  elsif !name.length.between?(1, 100)
    'List name must be 1-100 characters.'
  end
end

def todo_error(name)
  if !name.length.between?(1, 100)
    'To-do name must be 1-100 characters.'
  end
end






# Multiple List
# Each List has multiple todos (show # of incomplete tasks in each list)
# ( Sort alphabetically )
# - Add todos to each list
# - mark as completed (goes to bottom)
# - mark as uncompleted
# - Complete all (cross out list name to show its done)
# - edit list (change name of list)
# - delete item
#
# Lists are represented by URL IDs
#
# Errors/Validation:
# - Disallow empty todos
# - Disallow empty list names
# - Disallow invalid URL list IDs -> redirect to homepage w/ error msg
#

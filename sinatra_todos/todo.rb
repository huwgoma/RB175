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

helpers do
  # Counts
  def todo_count(list)
    list[:todos].size
  end

  def remaining_todo_count(list)
    list[:todos].count { |todo| !todo[:completed] }
  end

  # Complete/Incomplete
  # # Is an empty list complete or incomplete?
  # - Neither, so make a third method for the empty case
  def list_complete?(list)
    todo_count(list).positive? && remaining_todo_count(list).zero?
  end

  def list_incomplete?(list)
    list[:todos].any? { |todo| todo[:completed] == false }
  end

  # Order Lists/To-Dos by Completion Status
  def order_by_completion(elements, &criteria)
    partition = { complete: [], incomplete: [] }

    elements.each_with_index do |element, index|
      status = criteria.call(element) ? :complete : :incomplete
      partition[status] << { element: element, index: index }
    end

    partition[:incomplete] + partition[:complete]
  end

  def sort_lists(lists, &block)
    ordered_lists = order_by_completion(lists) { |list| list_complete?(list) }

    ordered_lists.each { |list| yield(list[:element], list[:index]) }
  end

  def sort_todos(todos, &block)
    ordered_todos = order_by_completion(todos) { |todo| todo[:completed] }
    
    ordered_todos.each { |todo| yield(todo[:element], todo[:index]) }
  end
end

get '/' do
  redirect '/lists'
end

# # # # #
# Lists #
# # # # #
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

# Display a specific List
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
    erb :edit_list
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

# # # # # #  
#  To-Dos #
# # # # # #
# Create a new to-do on a list
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
  redirect back
end

# Mark a specific to-do as complete or incomplete
post '/lists/:list_id/todos/:todo_id/toggle' do
  list_id = params[:list_id].to_i
  todo_id = params[:todo_id].to_i
  list = session[:lists][list_id]
  todo = list[:todos][todo_id]

  todo[:completed] = true?(params[:completed])
  session[:success] = 'To-do successfully updated.'
  redirect back
end

# Mark all to-dos as complete
post '/lists/:id/complete_all' do
  list_id = params[:id].to_i
  list = session[:lists][list_id]

  list[:todos].each { |todo| todo[:completed] = true }
  session[:success] = 'List successfully completed.'
  redirect back
end

# # # # # #
# Helpers # 
# # # # # #
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

# Sorting/Filtering
# - Place completed items at the bottom
# - Items of the same completion status should be 
require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

require 'yaml'

require 'pry'
# When the user loads the home page, redirect them to a page that lists all
#   user names. (loaded from users.yaml)
# Each username should contain a link to that user's page.
#   On each user page:
#   - Display their email address
#   - Display their interests (Comma-separated)
#   At the bottom of each user's page, list links to all other
#     users (excluding the current user)
# Add a layout. At the bottom of every page, display the message
#   "There are 3 users with a total of 9 interests"
#   - This should be dynamically determined based on the YAML
#     file's contents (`count_interests` view helper)
# Test adding a new user to user.yaml
# 

before do
  @users = YAML.load_file('users.yaml')
end

helpers do
  def list_users(current_user=nil)
    @users.keys.map do |user|
      next if current_user == user

      "<li>
        <a href=\"/users/#{user}\">#{user}</a>
      </li>"
    end.join
  end

  def count_interests
    @users.values.sum { |info| info[:interests].size }
  end
end

get '/' do
  redirect '/users/all'
end

get '/users/all' do
  erb :users
end

get '/users/:name' do
  params[:name] = params[:name].to_sym
  @user = @users.fetch(params[:name]) { redirect '/users/all' }

  erb :user
end
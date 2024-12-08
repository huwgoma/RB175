require 'sinatra'
require 'sinatra/reloader'



get '/users/profile/:user_id' do
  @user = User.find(params[:user_id])
  # Display the selected user's profile
  erb :example
end

get '/users/create' do
  erb :form
end

post '/users/create' do
  # Create a new User object with @name and @id:
  @user = User.new(params[:name])

  # Redirect to the newly-created user's profile
  redirect "/users/profile/#{@user.id}"
end

class User
  attr_reader :name, :id

  @@users = []

  def self.find(id)
    @@users[id.to_i]
  end

  def initialize(name)
    @name = name
    @id = @@users.size
    @@users << self
  end
end

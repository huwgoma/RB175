# app.rb
require 'bcrypt'

hashed_password = BCrypt::Password.create('password')
#=> "$2a$12$F1DD1lu.I3GWNEfS3Z2bkO5WoXnm9fjxfqCvcmMzmWm9Q4w1hawmi"

BCrypt::Password.new(hashed_password) == 'password'
#=> true


module BCrypt
  class Password < String
    def ==(password)
      # Hash the given password using the calling Password's @salt value.
      super(BCrypt::Engine.hash_secret(secret, @salt))
      # Compare the result using the superclass #== method (String#==).
    end
  end
end

#(note will be diff each time due to unique salt values)


# NOT A STRING - a subclass of String, BCrypt::Password
# BCrypt::Password#== hashes its plain text password argument using the calling object's @salt value
# - If the result is identical to the hashed password, then the given password must be equal to the 
# pre-hash password
BCrypt::Password.new(hashed_password) == 'password'
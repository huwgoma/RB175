# config.ru

# Load the application file.
require_relative 'app'

# Identify the Rack application (ie. Rack-compliant object)
# to invoke when requests are received.
run App.new          

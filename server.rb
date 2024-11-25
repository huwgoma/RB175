require 'socket'
require 'pry'

def parse_request(request_line)
  http_method, path, params, version = request_line.split(/(?: |\?)/)
  params = params.split('&').map { |pair| pair.split('=') }.to_h

  [http_method, path, params, version]
end

server = TCPServer.new('localhost', 3003)

loop do
  # Wait until a request is received - open connection to the client
  # => Client object
  client = server.accept

  # Return the first line of the request
  request_line = client.gets

  # Skip empty or /favicon.ico requests
  next if !request_line || request_line =~ /favicon/
  
  puts request_line

  # Extract request components
  http_method, path, params = parse_request(request_line)

  # Generate a response
  client.puts "HTTP/1.0 200 OK"
  client.puts "Content-Type: text/html"
  client.puts

  client.puts "<html>"
  client.puts "<body>"
  client.puts "<pre>"
  client.puts http_method, path, params
  client.puts "</pre>"

  client.puts "<h1>Rolls</h1>"
  # Roll the dice
  params['rolls'].to_i.times do
    client.puts "<p>", rand(params['sides'].to_i) + 1, "</p>"
  end

  client.puts "</body>"
  client.puts "</html>"

  # Close connection
  client.close
end

# Input:
#   String (request-line): GET /?rolls=2&sides=6 HTTP/1.1
# Output/Action:
#   Split the string into 3 strings:
#   - http_method: 'GET'
#   - path: '/'
#   - params = { 'rolls' => '2', 'sides' => '6' }

# Data:
# String given as input - GET /?rolls=2&sides=6 HTTP/1.1
# - The method is delimited from the path by a space.
# - The path is delimited from the query string by a ?.
#   - The query string's name=value pairs are delimited by &s.
# - The path is delimited from the HTTP version by a space.


# Split the string on spaces ( ) and question marks (?)
# => [GET, /, rolls=2&sides=6, HTTP/1.1]
# - method = first, path = second

# "rolls=2&sides=6" => { rolls => 2, sides = 6}
# Split params string on ampersands (&) to create an array of name=value pairs
# eg. [rolls=2, sides=6]
# Map over each name_value pair; for each pair, split the string on equals (=) to
#   create an array of [name, value] pairs.
# Then convert the whole array of [name, value] pairs to a hash


# Algorithm:
# Given an HTTP string, GET /?rolls=2&sides=6 HTTP/1.1
# - Split the string on spaces (' ') and question marks ('?')
#   => An array: [method, path, params, version]
# - Assign method and path to variables accordingly
# - Split the params string on ampersands ('&')
#   => An array: [name=value, name=value]
#   - (Map) Iterate through params. For each name=value pair:
#     - Split the current pair on equals ('='), yielding another array
#       [name, value]
#   EOI => An array with nested 2-element arrays - eg. [[name, value], [name, value]]
#   - Convert the array to a hash and assign to params variable.
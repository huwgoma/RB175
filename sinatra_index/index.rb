require "sinatra"
require "sinatra/reloader"
require 'tilt/erubis'

require 'pry'
# Sinatra Dynamic Directory Index
# By default, Sinatra will serve public/ files, given that public/ is in 
#   the same directory as the application.

# Reqs:
# 1) When a user visits the root path (/), they should be given a listing 
#    of all files in public/
#   - Only display the file name (not the path info)
# 2) When the user clicks one of the filenames, they should be redirected to
#    that file.
# 3) Create at least 5 files in public/
# 4) Add a parameter that controls the sort order of the file list.
#   - By default, sort in ascending (A-Z) order.
#   ?sort_by=descending (Z-A)
# 5) Display a link to reverse the sort order.
#   - Sort: "Ascending (A-Z)" or "Descending (Z-A)"

get '/' do
  # List all files in public/ (only filenames)
  @title = "Home" 
  
  @files = Dir.glob('public/*').map { |path| File.basename(path) }.sort
  @files.reverse! if params[:sort] == 'descending'

  erb :index
end
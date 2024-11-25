require_relative 'monroe'
require_relative 'advice'
require 'pry'

class App < Monroe
  def call(env)
    case env['PATH_INFO']
    when '/'
      status = 200
      headers = {'Content-Type' => 'text/html'}

      response(status, headers) { erb(:index) }
    when '/advice'
      advice = Advice.new.generate
      status = 200
      headers = {'Content-Type' => 'text/html'}

      response(status, headers) { erb(:advice, message: advice) }
    else
      status = 404
      headers = {'Content-Type' => 'text/html', 'Content-Length' => '60'}

      response(status, headers) { erb(:not_found) }
    end
  end
end
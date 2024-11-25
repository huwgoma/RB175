class Monroe
  def response(status, headers, body = '')
    body = yield if block_given?
    # Status Code Integer, Headers Hash, HTML String
    [status, headers, [body]]
  end

  def erb(filename, args = {})
    message = args[:message]
    # Pass `message` to ERB file via Binding 
    ERB.new(File.read("views/#{filename}.erb")).result(binding)
  end
end
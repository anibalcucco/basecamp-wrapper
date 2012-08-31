# ActiveResource connection patch to let users access the last response object and the headers.
#
# Example:
#   >> Basecamp::Message.find(:all, params => { :project_id => 1037 })
#   >> Basecamp::Message.connection.response["status"]
#   => "200 OK"
class ActiveResource::Connection
  alias_method :original_handle_response, :handle_response
  alias :static_default_header :default_header

  def handle_response(response)
    Thread.current[:active_resource_connection_headers] = response
    original_handle_response(response)
  end

  def response
    Thread.current[:active_resource_connection_headers]
  end

  def set_header(key, value)
    default_header.update(key => value)
  end
end

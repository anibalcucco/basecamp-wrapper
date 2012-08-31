module Basecamp; class Connection
  def initialize(master)
    @master = master
    @connection = Net::HTTP.new(master.site, master.use_ssl ? 443 : 80)
    @connection.use_ssl = master.use_ssl
    @connection.verify_mode = OpenSSL::SSL::VERIFY_NONE if master.use_ssl
  end

  def post(path, iostream, headers = {})
    request = Net::HTTP::Post.new(path, headers.merge('Accept' => 'application/xml'))
    request.basic_auth(@master.user, @master.password) unless @master.use_oauth
    request.body_stream = iostream
    request.content_length = iostream.size
    @connection.request(request)
  end

  def get(path, headers = {})
    request = Net::HTTP::Get.new(path, headers.merge('Accept' => 'application/xml'))
    request.basic_auth(@master.user, @master.password) unless @master.use_oauth
    @connection.request(request)
  end
end; end

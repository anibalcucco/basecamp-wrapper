module Basecamp
  class << self
    attr_accessor :use_xml
    attr_reader :site, :user, :password, :use_ssl, :use_oauth, :access_token

    def establish_connection!(site, user, password, use_ssl = false, use_xml = true)
      @site       = site
      @user       = user
      @password   = password
      @use_ssl    = use_ssl
      @use_xml    = use_xml
      @use_oauth  = false

      Resource.user     = user
      Resource.password = password
      Resource.site     = (use_ssl ? "https" : "http") + "://" + site
      Resource.format   = (use_xml ? :xml : :json)

      @connection = Connection.new(self)
    end

    def establish_oauth_connection!(site, access_token, use_ssl = false, use_xml = true)
      @site         = site
      @use_ssl      = use_ssl
      @use_xml      = use_xml
      @use_oauth    = true
      @access_token = access_token

      Resource.site         = (use_ssl ? "https" : "http") + "://" + site
      Resource.format       = (use_xml ? :xml : :json)
      Resource.connection.set_header('Authorization', "Bearer #{access_token}")

      @connection = Connection.new(self)
    end

    def connection
      @connection || raise('No connection established')
    end

    # Make a raw web-service request to Basecamp. This will return a Hash of
    # Arrays of the response, and may seem a little odd to the uninitiated.
    def request(path, parameters = {})
      headers = { "Content-Type" => content_type }
      headers.merge!('Authorization' => "Bearer #{@access_token}") if @use_oauth
      if parameters.empty?
        response = Basecamp.connection.get(path, headers)
      else
        response = Basecamp.connection.post(path, StringIO.new(convert_body(parameters)), headers)
      end

      if response.code.to_i / 100 == 2
        return {} if response.body.blank?
        result = XmlSimple.xml_in(response.body, 'keeproot' => true, 'contentkey' => '__content__', 'forcecontent' => true)
        typecast_value(result)
      else
        raise "#{response.message} (#{response.code})"
      end
    end

    # A convenience method for wrapping the result of a query in a Record
    # object. This assumes that the result is a singleton, not a collection.
    def record(path, parameters={})
      result = request(path, parameters)
      (result && !result.empty?) ? Record.new(result.keys.first, result.values.first) : nil
    end

    # A convenience method for wrapping the result of a query in Record
    # objects. This assumes that the result is a collection--any singleton
    # result will be wrapped in an array.
    def records(node, path, parameters={})
      result = request(path, parameters).values.first or return []
      result = result[node] or return []
      result = [result] unless Array === result
      result.map { |row| Record.new(node, row) }
    end

    private

      def convert_body(body)
        body = use_xml ? body.to_legacy_xml : body.to_yaml
      end

      def content_type
        use_xml ? "application/xml" : "application/x-yaml"
      end

      def typecast_value(value)
        case value
        when Hash
          if value.has_key?("__content__")
            content = translate_entities(value["__content__"]).strip
            case value["type"]
            when "integer"  then content.to_i
            when "boolean"  then content == "true"
            when "datetime" then Time.parse(content)
            when "date"     then Date.parse(content)
            else                 content
            end
          # a special case to work-around a bug in XmlSimple. When you have an empty
          # tag that has an attribute, XmlSimple will not add the __content__ key
          # to the returned hash. Thus, we check for the presense of the 'type'
          # attribute to look for empty, typed tags, and simply return nil for
          # their value.
          elsif value.keys == %w(type)
            nil
          elsif value["nil"] == "true"
            nil
          # another special case, introduced by the latest rails, where an array
          # type now exists. This is parsed by XmlSimple as a two-key hash, where
          # one key is 'type' and the other is the actual array value.
          elsif value.keys.length == 2 && value["type"] == "array"
            value.delete("type")
            typecast_value(value)
          else
            value.empty? ? nil : value.inject({}) do |h,(k,v)|
              h[k] = typecast_value(v)
              h
            end
          end
        when Array
          value.map! { |i| typecast_value(i) }
          case value.length
          when 0 then nil
          when 1 then value.first
          else value
          end
        else
          raise "can't typecast #{value.inspect}"
        end
      end

      def translate_entities(value)
        value.gsub(/&lt;/, "<").
              gsub(/&gt;/, ">").
              gsub(/&quot;/, '"').
              gsub(/&apos;/, "'").
              gsub(/&amp;/, "&")
      end
  end
end
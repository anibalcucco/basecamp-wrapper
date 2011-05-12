require 'net/https'
require 'yaml'
require 'date'
require 'time'
require 'active_resource'
require 'xmlsimple'

module Basecamp
  class Connection #:nodoc:
    def initialize(master)
      @master = master
      @connection = Net::HTTP.new(master.site, master.use_ssl ? 443 : 80)
      @connection.use_ssl = master.use_ssl
      @connection.verify_mode = OpenSSL::SSL::VERIFY_NONE if master.use_ssl
    end

    def post(path, body, headers = {})
      request = Net::HTTP::Post.new(path, headers.merge('Accept' => 'application/xml'))
      request.basic_auth(@master.user, @master.password)
      @connection.request(request, body)
    end

    def get(path, headers = {})
      request = Net::HTTP::Get.new(path, headers.merge('Accept' => 'application/xml'))
      request.basic_auth(@master.user, @master.password)
      @connection.request(request)
    end
  end

  class Resource < ActiveResource::Base #:nodoc:
    class << self
      def parent_resources(*parents)
        @parent_resources = parents
      end

      def element_name
        name.split(/::/).last.underscore
      end

      def prefix_source
        if @parent_resources
          @parent_resources.map { |resource| "/#{resource.to_s.pluralize}/:#{resource}_id" }.join + '/'
        else
          '/'
        end
      end

      def prefix(options = {})
        if options.any?
          options.map { |name, value| "/#{name.to_s.chomp('_id').pluralize}/#{value}" }.join + '/'
        else
          '/'
        end
      end
    end

    def prefix_options
      id ? {} : super
    end
  end

  class Project < Resource
    def time_entries(options = {})
      @time_entries ||= TimeEntry.find(:all, :params => options.merge(:project_id => id))
    end
  end

  class Company < Resource
    parent_resources :project

    def self.on_project(project_id, options = {})
      find(:all, :params => options.merge(:project_id => project_id))
    end
  end

  # == Creating different types of categories
  #
  # The type parameter is required when creating a category. For exampe, to
  # create an attachment category for a particular project:
  #
  #   c = Basecamp::Category.new(:project_id => 1037)
  #   c.type = 'attachment'
  #   c.name = 'Pictures'
  #   c.save # => true
  #
  class Category < Resource
    parent_resources :project

    def self.all(project_id, options = {})
      find(:all, :params => options.merge(:project_id => project_id))
    end

    def self.post_categories(project_id, options = {})
      find(:all, :params => options.merge(:project_id => project_id, :type => 'post'))
    end

    def self.attachment_categories(project_id, options = {})
      find(:all, :params => options.merge(:project_id => project_id, :type => 'attachment'))
    end
  end

  class Message < Resource
    parent_resources :project
    set_element_name 'post'

    # Returns the most recent 25 messages in the given project (and category,
    # if specified). If you need to retrieve older messages, use the archive
    # method instead. Example:
    #
    #   Basecamp::Message.recent(1037)
    #   Basecamp::Message.recent(1037, :category_id => 7301)
    #
    def self.recent(project_id, options = {})
      find(:all, :params => options.merge(:project_id => project_id))
    end

    # Returns a summary of all messages in the given project (and category, if
    # specified). The summary is simply the title and category of the message,
    # as well as the number of attachments (if any). Example:
    #
    #   Basecamp::Message.archive(1037)
    #   Basecamp::Message.archive(1037, :category_id => 7301)
    #
    def self.archive(project_id, options = {})
      find(:all, :params => options.merge(:project_id => project_id), :from => :archive)
    end

    def comments(options = {})
      @comments ||= Comment.find(:all, :params => options.merge(:post_id => id))
    end
  end

  # == Creating comments for multiple resources
  #
  # Comments can be created for messages, milestones, and to-dos, identified
  # by the <tt>post_id</tt>, <tt>milestone_id</tt>, and <tt>todo_item_id</tt>
  # params respectively.
  #
  # For example, to create a comment on the message with id #8675309:
  #
  #   c = Basecamp::Comment.new(:post_id => 8675309)
  #   c.body = 'Great tune'
  #   c.save # => true
  #
  # Similarly, to create a comment on a milestone:
  #
  #   c = Basecamp::Comment.new(:milestone_id => 8473647)
  #   c.body = 'Is this done yet?'
  #   c.save # => true
  #
  class Comment < Resource
    parent_resources :post, :milestone, :todo_item
  end

  class TodoList < Resource
    parent_resources :project

    # Returns all lists for a project. If complete is true, only completed lists
    # are returned. If complete is false, only uncompleted lists are returned.
    def self.all(project_id, complete = nil)
      filter = case complete
        when nil   then "all"
        when true  then "finished"
        when false then "pending"
        else raise ArgumentError, "invalid value for `complete'"
      end

      find(:all, :params => { :project_id => project_id, :filter => filter })
    end

    def todo_items(options = {})
      @todo_items ||= TodoItem.find(:all, :params => options.merge(:todo_list_id => id))
    end
  end

  class TodoItem < Resource
    parent_resources :todo_list

    def todo_list(options = {})
      @todo_list ||= TodoList.find(todo_list_id, options)
    end

    def time_entries(options = {})
      @time_entries ||= TimeEntry.find(:all, :params => options.merge(:todo_item_id => id))
    end

    def comments(options = {})
      @comments ||= Comment.find(:all, :params => options.merge(:todo_item_id => id))
    end

    def complete!
      put(:complete)
    end

    def uncomplete!
      put(:uncomplete)
    end
  end

  class TimeEntry < Resource
    parent_resources :project, :todo_item

    def self.all(project_id, page = 0)
      find(:all, :params => { :project_id => project_id, :page => page })
    end

    def self.report(options={})
      find(:all, :from => :report, :params => options)
    end
  end

  class Category < Resource
    parent_resources :project
  end

  class Attachment
    attr_accessor :id, :filename, :content

    def self.create(filename, content)
      returning new(filename, content) do |attachment|
        attachment.save
      end
    end

    def initialize(filename, content)
      @filename, @content = filename, content
    end

    def attributes
      { :file => id, :original_filename => filename }
    end

    def to_xml(options = {})
      { :file => attributes }.to_xml(options)
    end

    def inspect
      to_s
    end

    def save
      response = Basecamp.connection.post('/upload', content, 'Content-Type' => 'application/octet-stream')

      if response.code == '200'
        self.id = Hash.from_xml(response.body)['upload']['id']
        true
      else
        raise "Could not save attachment: #{response.message} (#{response.code})"
      end
    end
  end

  class Record #:nodoc:
    attr_reader :type

    def initialize(type, hash)
      @type, @hash = type, hash
    end

    def [](name)
      name = dashify(name)

      case @hash[name]
      when Hash then 
        @hash[name] = if (@hash[name].keys.length == 1 && @hash[name].values.first.is_a?(Array))
          @hash[name].values.first.map { |v| Record.new(@hash[name].keys.first, v) }
        else
          Record.new(name, @hash[name])
        end
      else
        @hash[name]
      end
    end

    def id
      @hash['id']
    end

    def attributes
      @hash.keys
    end

    def respond_to?(sym)
      super || @hash.has_key?(dashify(sym))
    end

    def method_missing(sym, *args)
      if args.empty? && !block_given? && respond_to?(sym)
        self[sym]
      else
        super
      end
    end

    def to_s
      "\#<Record(#{@type}) #{@hash.inspect[1..-2]}>"
    end

    def inspect
      to_s
    end

    private

      def dashify(name)
        name.to_s.tr("_", "-")
      end
  end

  attr_accessor :use_xml

  class << self
    attr_reader :site, :user, :password, :use_ssl

    def establish_connection!(site, user, password, use_ssl = false)
      @site     = site
      @user     = user
      @password = password
      @use_ssl  = use_ssl

      Resource.user = user
      Resource.password = password
      Resource.site = (use_ssl ? "https" : "http") + "://" + site

      @connection = Connection.new(self)
    end

    def connection
      @connection || raise('No connection established')
    end

    def get_token
      response = @connection.get('/me.xml')
      xml = XmlSimple.xml_in(response.body)
      xml['token'][0]
    end
  end

  def initialize
    @use_xml = false
  end

  # ==========================================================================
  # PEOPLE
  # ==========================================================================

  # Return an array of the people in the given company. If the project-id is
  # given, only people who have access to the given project will be returned.
  def people(company_id, project_id=nil)
    url = project_id ? "/projects/#{project_id}" : ""
    url << "/contacts/people/#{company_id}"
    records "person", url
  end

  # Return information about the person with the given id
  def person(id)
    record "/contacts/person/#{id}"
  end

  # ==========================================================================
  # MILESTONES
  # ==========================================================================

  # Returns a list of all milestones for the given project, optionally filtered
  # by whether they are completed, late, or upcoming.
  def milestones(project_id, find = 'all')
    records "milestone", "/projects/#{project_id}/milestones/list", :find => find
  end

  # Create a new milestone for the given project. +data+ must be hash of the
  # values to set, including +title+, +deadline+, +responsible_party+, and
  # +notify+.
  def create_milestone(project_id, data)
    create_milestones(project_id, [data]).first
  end

  # As #create_milestone, but can create multiple milestones in a single
  # request. The +milestones+ parameter must be an array of milestone values as
  # described in #create_milestone.
  def create_milestones(project_id, milestones)
    records "milestone", "/projects/#{project_id}/milestones/create", :milestone => milestones
  end

  # Updates an existing milestone.
  def update_milestone(id, data, move = false, move_off_weekends = false)
    record "/milestones/update/#{id}", :milestone => data,
      :move_upcoming_milestones => move,
      :move_upcoming_milestones_off_weekends => move_off_weekends
  end

  # Destroys the milestone with the given id.
  def delete_milestone(id)
    record "/milestones/delete/#{id}"
  end

  # Complete the milestone with the given id
  def complete_milestone(id)
    record "/milestones/complete/#{id}"
  end

  # Uncomplete the milestone with the given id
  def uncomplete_milestone(id)
    record "/milestones/uncomplete/#{id}"
  end

  private

    # Make a raw web-service request to Basecamp. This will return a Hash of
    # Arrays of the response, and may seem a little odd to the uninitiated.
    def request(path, parameters = {})
      response = Basecamp.connection.post(path, convert_body(parameters), "Content-Type" => content_type)

      if response.code.to_i / 100 == 2
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

# A minor hack to let Xml-Simple serialize symbolic keys in hashes
class Symbol
  def [](*args)
    to_s[*args]
  end
end

class Hash
  def to_legacy_xml
    XmlSimple.xml_out({:request => self}, 'keeproot' => true, 'noattr' => true)
  end
end

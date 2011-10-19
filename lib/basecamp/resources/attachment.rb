module Basecamp; class Attachment
  attr_accessor :id, :filename, :content, :category_id

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
    { :file => attributes, :category_id => category_id }.to_xml(options)
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
end; end
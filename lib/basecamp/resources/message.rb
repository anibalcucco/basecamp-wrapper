module Basecamp; class Message < Basecamp::Resource
  parent_resources :project
  self.element_name = 'post'

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
    all(:params => options.merge(:project_id => project_id), :from => :archive)
  end

  def comments(options = {})
    @comments ||= Comment.all(:params => options.merge(:post_id => id))
  end
end; end

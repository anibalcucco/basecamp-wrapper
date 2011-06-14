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
module Basecamp; class Category < Basecamp::Resource
  def self.all(project_id, options = {})
    find(:all, :params => options.merge(:project_id => project_id))
  end

  def self.post_categories(project_id, options = {})
    find(:all, :params => options.merge(:project_id => project_id, :type => 'post'))
  end

  def self.attachment_categories(project_id, options = {})
    find(:all, :params => options.merge(:project_id => project_id, :type => 'attachment'))
  end
end; end

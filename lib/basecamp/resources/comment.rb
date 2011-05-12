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

module Basecamp; class Comment < Basecamp::Resource
  parent_resources :post, :milestone, :todo_item
end; end
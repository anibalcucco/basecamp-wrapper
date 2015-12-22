module Basecamp; class TimeEntry < Basecamp::Resource
  parent_resources :project

  def self.all(project_id, page = 0)
    find(:all, :params => { :project_id => project_id, :page => page })
  end

  def self.report(options={})
    find(:all, :from => :report, :params => options)
  end

  def todo_item
    @todo_item ||= TodoItem.find(todo_item_id)
  end

  def prefix_options
    { :todo_item_id => todo_item_id }
  end
end; end

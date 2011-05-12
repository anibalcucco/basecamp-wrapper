module Basecamp; class TodoItem < Basecamp::Resource
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
end; end
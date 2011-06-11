module Basecamp; class Project < Basecamp::Resource
  def messages(options = {})
    @messages ||= Message.all(:params => options.merge(:project_id => id))
  end

  def time_entries(options = {})
    @time_entries ||= TimeEntry.find(:all, :params => options.merge(:project_id => id))
  end

  def todo_lists(options = {})
    @todo_lists ||= TodoList.find(:all, :params => options.merge(:project_id => id))
  end

  def categories(options = {})
    @categories ||= Category.all(:params => options.merge(:project_id => id))
  end
end; end

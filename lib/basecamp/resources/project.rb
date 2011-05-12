module Basecamp; class Project < Basecamp::Resource
  def time_entries(options = {})
    @time_entries ||= TimeEntry.find(:all, :params => options.merge(:project_id => id))
  end
end; end
module Basecamp; class Company < Basecamp::Resource
  parent_resources :project

  def self.on_project(project_id, options = {})
    find(:all, :params => options.merge(:project_id => project_id))
  end
end; end
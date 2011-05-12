module Basecamp; class Milestone
  class << self
    # Returns a list of all milestones for the given project, optionally filtered
    # by whether they are completed, late, or upcoming.
    def list(project_id, find = 'all')
      Basecamp.records "milestone", "/projects/#{project_id}/milestones/list", :find => find
    end

    # Create a new milestone for the given project. +data+ must be hash of the
    # values to set, including +title+, +deadline+, +responsible_party+, and
    # +notify+.
    def create(project_id, data)
      create_milestones(project_id, [data]).first
    end

    # As #create_milestone, but can create multiple milestones in a single
    # request. The +milestones+ parameter must be an array of milestone values as
    # described in #create_milestone.
    def create_milestones(project_id, milestones)
      Basecamp.records "milestone", "/projects/#{project_id}/milestones/create", :milestone => milestones
    end

    # Updates an existing milestone.
    def update(id, data, move = false, move_off_weekends = false)
      Basecamp.record "/milestones/update/#{id}", :milestone => data,
        :move_upcoming_milestones => move,
        :move_upcoming_milestones_off_weekends => move_off_weekends
    end

    # Destroys the milestone with the given id.
    def delete(id)
      Basecamp.record "/milestones/delete/#{id}"
    end

    # Complete the milestone with the given id
    def complete(id)
      Basecamp.record "/milestones/complete/#{id}"
    end

    # Uncomplete the milestone with the given id
    def uncomplete(id)
      Basecamp.record "/milestones/uncomplete/#{id}"
    end
  end
end; end
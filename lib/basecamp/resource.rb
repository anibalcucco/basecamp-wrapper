module Basecamp; class Resource < ActiveResource::Base
  class << self
    def parent_resources(*parents)
      @parent_resources = parents
    end

    def prefix_source
      if @parent_resources
        @parent_resources.map { |resource| "/#{resource.to_s.pluralize}/:#{resource}_id" }.join + '/'
      else
        '/'
      end
    end

    def prefix(options = {})
      puts options.inspect
      if options.any?
        options.map { |name, value| "/#{name.to_s.chomp('_id').pluralize}/#{value}" }.join + '/'
      else
        '/'
      end
    end
  end

  def prefix_optionsa
    id ? {} : super
  end
end; end

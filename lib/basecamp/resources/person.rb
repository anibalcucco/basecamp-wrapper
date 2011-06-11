module Basecamp; class Person < Basecamp::Resource
  #parent_resources :company, :projects

  def self.me
    hash = get(:me)
    Basecamp::Person.new(hash)
  end
end; end

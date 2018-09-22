module Callable
 extend ActiveSupport::Concern
 class_methods do
   def call(*args)
     new(*args).call
   end
 end

 class Result
   attr_reader :resource

   def initialize(resource, success)
     @resource = resource
     @success = success
   end

   def success?
     @success
   end
 end
 private_constant :Result
end

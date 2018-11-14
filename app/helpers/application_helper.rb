module ApplicationHelper
  # Returns the CSS class to add to the body element.
  # The body class will contain the controller and action names.
  # @return [String]
  def body_class
    body_classes = []
    body_classes << controller.controller_name.dasherize
    # Use the new class for styling the create action
    # and use the edit class for styling the update action.
    body_classes <<
      if controller.action_name == "create"
        "new"
      elsif controller.action_name == "update"
        "edit"
      else
        controller.action_name.dasherize
      end
    # Allow an additional class to be set by the controller
    body_classes << @body_class if @body_class
    body_classes.join(" ")
  end
end

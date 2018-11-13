import { Controller } from "stimulus";
import Rails from "rails-ujs";

export class ApplicationController extends Controller {
  getControllerByIdentifier(identifier) {
    return this.application.controllers.find(controller => {
      return controller.context.identifier === identifier;
    });
  }

  getControllersByIdentifier(identifier) {
    return this.application.controllers.filter(controller => {
      return controller.context.identifier === identifier;
    });
  }
}

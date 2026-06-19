# frozen_string_literal: true

# Temporary home controller — will be replaced in a later story (2.x or 1.5)
# with the real dashboard/calendar view.
class HomeController < ApplicationController
  # Temporary root — replaced by dashboard/calendar in Story 2.x; no Pundit policy needed.
  # Story 1.5 will add: before_action :require_profile_complete
  # This skip list may need to be extended for the profile/sessions controllers.
  skip_after_action :verify_authorized, only: :index

  def index
    # Protected by ApplicationController#require_authentication
  end
end

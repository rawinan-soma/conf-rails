# frozen_string_literal: true

# Temporary home controller — will be replaced in a later story (2.x or 1.5)
# with the real dashboard/calendar view.
class HomeController < ApplicationController
  def index
    # Protected by ApplicationController#require_authentication
  end
end

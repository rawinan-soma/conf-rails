# frozen_string_literal: true

class AdminSidebarComponent < ApplicationComponent
  def initialize(nav_items: [])
    @nav_items = nav_items
  end
end

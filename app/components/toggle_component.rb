# frozen_string_literal: true

class ToggleComponent < ApplicationComponent
  def initialize(form: nil, attribute: nil, label:, checked: false, **html_options)
    @form = form
    @attribute = attribute
    @label = label
    @checked = checked
    @html_options = html_options
  end

  def checked?
    @checked
  end
end

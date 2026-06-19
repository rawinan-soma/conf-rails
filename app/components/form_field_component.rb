# frozen_string_literal: true

class FormFieldComponent < ApplicationComponent
  def initialize(form: nil, attribute: nil, label:, hint: nil, error: nil, required: false, **html_options)
    @form = form
    @attribute = attribute
    @label = label
    @hint = hint
    @error = error
    @required = required
    @html_options = html_options
  end

  def error?
    @error.present?
  end

  def required?
    @required
  end

  def field_id
    @attribute ? "field_#{@attribute}" : nil
  end
end

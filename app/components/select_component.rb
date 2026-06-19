# frozen_string_literal: true

class SelectComponent < ApplicationComponent
  def initialize(form: nil, attribute: nil, label:, options: [], include_blank: nil, error: nil, required: false, **html_options)
    @form = form
    @attribute = attribute
    @label = label
    @options = options
    @include_blank = include_blank
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
    @attribute ? "select_#{@attribute}" : nil
  end
end

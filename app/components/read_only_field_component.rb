# frozen_string_literal: true

class ReadOnlyFieldComponent < ApplicationComponent
  def initialize(label:, value:)
    @label = label
    @value = value
  end
end

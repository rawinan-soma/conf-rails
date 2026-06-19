# frozen_string_literal: true

class ModalComponent < ApplicationComponent
  renders_one :body
  renders_one :footer

  def initialize(title:, id:, variant: :default)
    @title = title
    @id = id
    @variant = variant
  end
end

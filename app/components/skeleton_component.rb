# frozen_string_literal: true

class SkeletonComponent < ApplicationComponent
  VARIANTS = %i[card list_row table_row calendar_grid].freeze

  def initialize(variant: :card, rows: 1)
    @variant = variant.to_sym
    @rows = rows
  end

  def variant
    @variant
  end

  def rows
    @rows
  end
end

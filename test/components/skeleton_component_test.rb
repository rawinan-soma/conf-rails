# frozen_string_literal: true

# ATDD Red-Phase Tests — Story 1.2: Core Design System & ViewComponent UI Library
# Subgroup: SkeletonComponent
#
# TDD RED PHASE: All tests use `skip` until SkeletonComponent is implemented.
#
# Acceptance Criteria Covered:
#   AC-2: SkeletonComponent renders grey-green shimmer blocks shaped like content.
#         Variants: :card, :list_row, :table_row, :calendar_grid.

require "test_helper"

class SkeletonComponentTest < ViewComponent::TestCase
  # ---------------------------------------------------------------------------
  # P1 — Card variant renders
  # ---------------------------------------------------------------------------

  test "[P1] card variant renders skeleton element" do
    skip "RED PHASE — SkeletonComponent not yet implemented"
    render_inline(SkeletonComponent.new(variant: :card))
    assert_selector ".skeleton, [data-skeleton]"
  end

  # ---------------------------------------------------------------------------
  # P1 — List row variant
  # ---------------------------------------------------------------------------

  test "[P1] list_row variant renders skeleton element" do
    skip "RED PHASE — SkeletonComponent not yet implemented"
    render_inline(SkeletonComponent.new(variant: :list_row))
    assert_selector ".skeleton, [data-skeleton]"
  end

  # ---------------------------------------------------------------------------
  # P1 — Table row variant with rows kwarg
  # ---------------------------------------------------------------------------

  test "[P1] table_row variant renders multiple skeleton rows when rows kwarg given" do
    skip "RED PHASE — SkeletonComponent not yet implemented"
    render_inline(SkeletonComponent.new(variant: :table_row, rows: 3))
    assert_selector ".skeleton", minimum: 3
  end

  # ---------------------------------------------------------------------------
  # P1 — Calendar grid variant
  # ---------------------------------------------------------------------------

  test "[P1] calendar_grid variant renders skeleton element" do
    skip "RED PHASE — SkeletonComponent not yet implemented"
    render_inline(SkeletonComponent.new(variant: :calendar_grid))
    assert_selector ".skeleton, [data-skeleton]"
  end

  # ---------------------------------------------------------------------------
  # P2 — Default variant renders without raising
  # ---------------------------------------------------------------------------

  test "[P2] renders default variant without raising" do
    skip "RED PHASE — SkeletonComponent not yet implemented"
    assert_nothing_raised do
      render_inline(SkeletonComponent.new)
    end
  end

  # ---------------------------------------------------------------------------
  # P2 — Rows kwarg defaults to 1
  # ---------------------------------------------------------------------------

  test "[P2] defaults to 1 row when rows kwarg not provided" do
    skip "RED PHASE — SkeletonComponent not yet implemented"
    render_inline(SkeletonComponent.new(variant: :list_row))
    assert_selector ".skeleton", count: 1
  end
end

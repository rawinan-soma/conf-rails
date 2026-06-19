# frozen_string_literal: true

# ATDD Red-Phase Tests — Story 1.2: Core Design System & ViewComponent UI Library
# Subgroup: SelectComponent
#
# TDD RED PHASE: All tests use `skip` until SelectComponent is implemented.
#
# Acceptance Criteria Covered:
#   AC-2: Select renders per DESIGN.md specs (card fill, border, radius sm,
#         focus ring ≥2px green-500, always-visible label, no color-alone meaning).

require "test_helper"

class SelectComponentTest < ViewComponent::TestCase
  # ---------------------------------------------------------------------------
  # P0 — Renders select with label and options
  # ---------------------------------------------------------------------------

  test "[P0] renders select element with visible label" do
    render_inline(SelectComponent.new(attribute: :title, label: "Title",
                                       options: [ %w[Mr mr], %w[Mrs mrs], %w[Ms ms] ]))
    assert_selector "label", text: "Title"
    assert_selector "select"
    assert_selector "option[value='mr']", text: "Mr"
    assert_selector "option[value='mrs']", text: "Mrs"
  end

  test "[P0] label is associated with select via for/id" do
    render_inline(SelectComponent.new(attribute: :meal_type, label: "Meal Type",
                                       options: [ %w[Standard standard], %w[Vegetarian vegetarian] ]))
    label = page.find("label")
    select = page.find("select")
    assert_equal select["id"], label["for"],
                 "label[for] must match select[id]"
  end

  # ---------------------------------------------------------------------------
  # P0 — Blank option
  # ---------------------------------------------------------------------------

  test "[P0] renders blank option when include_blank is provided" do
    render_inline(SelectComponent.new(attribute: :title, label: "Title",
                                       options: [ %w[Mr mr] ],
                                       include_blank: "Select title..."))
    assert_selector "option[value='']", text: "Select title..."
  end

  # ---------------------------------------------------------------------------
  # P1 — Error state
  # ---------------------------------------------------------------------------

  test "[P1] renders error message when error kwarg provided" do
    render_inline(SelectComponent.new(attribute: :title, label: "Title",
                                       options: [ %w[Mr mr] ],
                                       error: "can't be blank"))
    assert_text "can't be blank"
    assert page.has_css?(".select-error, [aria-invalid='true']"),
           "error state must mark select with .select-error or aria-invalid"
  end

  # ---------------------------------------------------------------------------
  # P1 — Design for meal-type picker (future story use case)
  # ---------------------------------------------------------------------------

  test "[P1] meal type picker options are rendered correctly" do
    meal_options = [
      [ "Standard", "standard" ],
      [ "Vegetarian", "vegetarian" ],
      [ "Vegan", "vegan" ],
      [ "Halal", "halal" ]
    ]
    render_inline(SelectComponent.new(attribute: :meal_type, label: "Meal Type",
                                       options: meal_options))
    meal_options.each do |label, value|
      assert_selector "option[value='#{value}']", text: label
    end
  end

  # ---------------------------------------------------------------------------
  # P2 — Clean render without error
  # ---------------------------------------------------------------------------

  test "[P2] renders cleanly without error state by default" do
    render_inline(SelectComponent.new(attribute: :title, label: "Title",
                                       options: [ %w[Mr mr] ]))
    assert_no_selector ".select-error, [aria-invalid='true']"
  end
end

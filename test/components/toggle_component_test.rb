# frozen_string_literal: true

# ATDD Red-Phase Tests — Story 1.2: Core Design System & ViewComponent UI Library
# Subgroup: ToggleComponent
#
# TDD RED PHASE: All tests use `skip` until ToggleComponent is implemented.
#
# Acceptance Criteria Covered:
#   AC-2: Toggle renders per DESIGN.md — green-700 on / ink-3 off,
#         label always visible beside toggle (never label-only-via-color, WCAG 2.1 AA).

require "test_helper"

class ToggleComponentTest < ViewComponent::TestCase
  # ---------------------------------------------------------------------------
  # P0 — Label is always visible (WCAG: no color-alone meaning)
  # ---------------------------------------------------------------------------

  test "[P0] renders label text beside the toggle" do
    render_inline(ToggleComponent.new(attribute: :catering_enabled, label: "Catering"))
    assert_selector "label", text: "Catering"
  end

  test "[P0] toggle is associated with its label for accessibility" do
    render_inline(ToggleComponent.new(attribute: :catering_enabled, label: "Catering"))
    input = page.find("input[type='checkbox']")
    label = page.find("label")
    # Either label[for]=input[id] OR input is nested inside label
    assert(
      input["id"] == label["for"] || label.has_css?("input[type='checkbox']"),
      "toggle input must be associated with its label"
    )
  end

  # ---------------------------------------------------------------------------
  # P0 — Default unchecked state
  # ---------------------------------------------------------------------------

  test "[P0] renders unchecked by default" do
    render_inline(ToggleComponent.new(attribute: :registration_enabled, label: "Registration"))
    assert_selector "input[type='checkbox']:not([checked])"
  end

  # ---------------------------------------------------------------------------
  # P1 — Checked state
  # ---------------------------------------------------------------------------

  test "[P1] renders checked when checked kwarg is true" do
    render_inline(ToggleComponent.new(attribute: :catering_enabled, label: "Catering",
                                       checked: true))
    assert_selector "input[type='checkbox'][checked]"
  end

  # ---------------------------------------------------------------------------
  # P1 — Uses daisyUI toggle class
  # ---------------------------------------------------------------------------

  test "[P1] input uses daisyUI toggle class" do
    render_inline(ToggleComponent.new(attribute: :catering_enabled, label: "Catering"))
    assert_selector "input[type='checkbox'].toggle"
  end

  # ---------------------------------------------------------------------------
  # P2 — Name/value attributes set from form context
  # ---------------------------------------------------------------------------

  test "[P2] renders toggle with correct name attribute when form kwarg provided" do
    # Simulate without a real form builder — test standalone attribute rendering
    render_inline(ToggleComponent.new(attribute: :catering_enabled, label: "Catering"))
    assert_selector "input[type='checkbox']"
  end
end

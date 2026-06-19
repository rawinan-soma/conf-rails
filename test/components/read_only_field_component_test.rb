# frozen_string_literal: true

# ATDD Red-Phase Tests — Story 1.2: Core Design System & ViewComponent UI Library
# Subgroup: ReadOnlyFieldComponent
#
# TDD RED PHASE: All tests use `skip` until ReadOnlyFieldComponent is implemented.
#
# Acceptance Criteria Covered:
#   AC-2: ReadOnlyField is visually distinct from editable FormFieldComponent
#         (cream-100 fill, ink-2 text, NOT focusable as input).

require "test_helper"

class ReadOnlyFieldComponentTest < ViewComponent::TestCase
  # ---------------------------------------------------------------------------
  # P1 — Renders label and value
  # ---------------------------------------------------------------------------

  test "[P1] renders label and value text" do
    skip "RED PHASE — ReadOnlyFieldComponent not yet implemented"
    render_inline(ReadOnlyFieldComponent.new(label: "Organizer", value: "Rawinan Soma"))
    assert_selector "label", text: "Organizer"
    assert_text "Rawinan Soma"
  end

  # ---------------------------------------------------------------------------
  # P1 — Not rendered as a focusable input
  # ---------------------------------------------------------------------------

  test "[P1] value is not rendered as a focusable input element" do
    skip "RED PHASE — ReadOnlyFieldComponent not yet implemented"
    render_inline(ReadOnlyFieldComponent.new(label: "Phone", value: "+66 81 234 5678"))
    # Must NOT be an editable input — it's a display-only field
    assert_no_selector "input:not([readonly]):not([disabled])"
    assert_no_selector "textarea:not([readonly]):not([disabled])"
  end

  # ---------------------------------------------------------------------------
  # P1 — Visually distinct from FormFieldComponent (different bg class)
  # ---------------------------------------------------------------------------

  test "[P1] read-only field has visually distinct styling from editable field" do
    skip "RED PHASE — ReadOnlyFieldComponent not yet implemented"
    render_inline(ReadOnlyFieldComponent.new(label: "Contact", value: "test@example.com"))
    # cream-100 fill class or a .read-only-field wrapper distinguishing it
    assert page.has_css?(".read-only-field, [data-read-only], .bg-cream-100, [class*='read-only']"),
           "read-only field must have visually distinct styling from editable FormFieldComponent"
  end

  # ---------------------------------------------------------------------------
  # P2 — Empty value renders gracefully
  # ---------------------------------------------------------------------------

  test "[P2] renders gracefully when value is blank" do
    skip "RED PHASE — ReadOnlyFieldComponent not yet implemented"
    assert_nothing_raised do
      render_inline(ReadOnlyFieldComponent.new(label: "Notes", value: nil))
    end
    assert_selector "label", text: "Notes"
  end
end

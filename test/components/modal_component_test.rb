# frozen_string_literal: true

# ATDD Red-Phase Tests — Story 1.2: Core Design System & ViewComponent UI Library
# Subgroup: ModalComponent
#
# TDD RED PHASE: All tests use `skip` until ModalComponent is implemented.
#
# Acceptance Criteria Covered:
#   AC-2: Modal has role="dialog", aria-modal="true", aria-labelledby (WCAG 2.1 AA).
#         Focus trap when open. Title slot, body slot, confirm/cancel actions.

require "test_helper"

class ModalComponentTest < ViewComponent::TestCase
  # ---------------------------------------------------------------------------
  # P0 — ARIA role and attributes (accessibility hard requirement)
  # ---------------------------------------------------------------------------

  test "[P0] modal element has role=dialog" do
    skip "RED PHASE — ModalComponent not yet implemented"
    render_inline(ModalComponent.new(title: "Confirm Deletion", id: "confirm-modal"))
    assert_selector "[role='dialog']"
  end

  test "[P0] modal has aria-modal=true" do
    skip "RED PHASE — ModalComponent not yet implemented"
    render_inline(ModalComponent.new(title: "Confirm", id: "confirm-modal"))
    assert_selector "[aria-modal='true']"
  end

  test "[P0] modal has aria-labelledby referencing the title element" do
    skip "RED PHASE — ModalComponent not yet implemented"
    render_inline(ModalComponent.new(title: "Deactivate Room", id: "deactivate-modal"))
    dialog = page.find("[role='dialog']")
    labelledby = dialog["aria-labelledby"]
    assert labelledby.present?, "dialog must have aria-labelledby"
    assert page.has_css?("##{labelledby}"),
           "element with id=#{labelledby} must exist (modal title)"
    assert_selector "##{labelledby}", text: "Deactivate Room"
  end

  # ---------------------------------------------------------------------------
  # P0 — Close button with i18n label
  # ---------------------------------------------------------------------------

  test "[P0] modal renders close button with aria label" do
    skip "RED PHASE — ModalComponent not yet implemented"
    render_inline(ModalComponent.new(title: "Confirm", id: "confirm-modal"))
    assert_selector "button[aria-label], button[title]"
  end

  # ---------------------------------------------------------------------------
  # P0 — Stimulus controller for open/close
  # ---------------------------------------------------------------------------

  test "[P0] modal root element has Stimulus controller attribute" do
    skip "RED PHASE — ModalComponent not yet implemented"
    render_inline(ModalComponent.new(title: "Confirm", id: "test-modal"))
    assert_selector "[data-controller]"
  end

  # ---------------------------------------------------------------------------
  # P1 — Title is rendered
  # ---------------------------------------------------------------------------

  test "[P1] renders provided title" do
    skip "RED PHASE — ModalComponent not yet implemented"
    render_inline(ModalComponent.new(title: "Are you sure?", id: "confirm-modal"))
    assert_text "Are you sure?"
  end

  # ---------------------------------------------------------------------------
  # P1 — ID attribute is applied to modal element
  # ---------------------------------------------------------------------------

  test "[P1] modal has the provided id attribute" do
    skip "RED PHASE — ModalComponent not yet implemented"
    render_inline(ModalComponent.new(title: "Confirm", id: "my-modal"))
    assert_selector "#my-modal, [data-modal-id='my-modal']"
  end

  # ---------------------------------------------------------------------------
  # P1 — Danger variant for destructive confirmations (Story 2.6 use case)
  # ---------------------------------------------------------------------------

  test "[P1] danger variant renders without raising" do
    skip "RED PHASE — ModalComponent not yet implemented"
    assert_nothing_raised do
      render_inline(ModalComponent.new(title: "Deactivate Room?", id: "deactivate-modal",
                                        variant: :danger))
    end
    assert_text "Deactivate Room?"
  end

  # ---------------------------------------------------------------------------
  # P2 — daisyUI modal class
  # ---------------------------------------------------------------------------

  test "[P2] modal uses daisyUI modal class" do
    skip "RED PHASE — ModalComponent not yet implemented"
    render_inline(ModalComponent.new(title: "Info", id: "info-modal"))
    assert_selector ".modal"
  end
end

# frozen_string_literal: true

# ATDD Red-Phase Tests — Story 1.2: Core Design System & ViewComponent UI Library
# Subgroup: ButtonComponent
#
# TDD RED PHASE: All tests use `skip` until ButtonComponent is implemented.
# Remove `skip` line-by-line as each task is implemented and tests go green.
#
# Acceptance Criteria Covered:
#   AC-2: Button/form-field/select/toggle/badge/modal/toast/skeleton/empty-state render
#         per DESIGN.md specs, with visible focus rings (≥2px green-500),
#         always-visible labels, and no color-alone meaning (WCAG 2.1 AA).

require "test_helper"

class ButtonComponentTest < ViewComponent::TestCase
  # ---------------------------------------------------------------------------
  # P0 — Primary variant (green-700 fill, white text)
  # ---------------------------------------------------------------------------

  test "[P0] renders primary button with label" do
    skip "RED PHASE — ButtonComponent not yet implemented"
    render_inline(ButtonComponent.new(label: "Submit"))
    assert_selector "button", text: "Submit"
    assert_selector "button.btn-primary"
  end

  test "[P0] primary button has btn-primary class by default" do
    skip "RED PHASE — ButtonComponent not yet implemented"
    render_inline(ButtonComponent.new(label: "Save"))
    assert_selector "button[type='button'].btn-primary"
  end

  # ---------------------------------------------------------------------------
  # P0 — Loading state
  # ---------------------------------------------------------------------------

  test "[P0] loading state disables button and shows spinner" do
    skip "RED PHASE — ButtonComponent not yet implemented"
    render_inline(ButtonComponent.new(label: "Saving...", loading: true))
    assert_selector "button[disabled]"
    assert_selector "button.loading"
  end

  # ---------------------------------------------------------------------------
  # P0 — Link rendering (renders as <a> when href given)
  # ---------------------------------------------------------------------------

  test "[P0] renders as anchor tag when href is provided" do
    skip "RED PHASE — ButtonComponent not yet implemented"
    render_inline(ButtonComponent.new(label: "Go", href: "/conferences"))
    assert_selector "a[href='/conferences']", text: "Go"
    assert_no_selector "button"
  end

  # ---------------------------------------------------------------------------
  # P1 — Secondary variant
  # ---------------------------------------------------------------------------

  test "[P1] renders secondary variant" do
    skip "RED PHASE — ButtonComponent not yet implemented"
    render_inline(ButtonComponent.new(label: "Cancel", variant: :secondary))
    assert_selector "button.btn-secondary", text: "Cancel"
  end

  # ---------------------------------------------------------------------------
  # P1 — Ghost variant
  # ---------------------------------------------------------------------------

  test "[P1] renders ghost variant" do
    skip "RED PHASE — ButtonComponent not yet implemented"
    render_inline(ButtonComponent.new(label: "More", variant: :ghost))
    assert_selector "button.btn-ghost", text: "More"
  end

  # ---------------------------------------------------------------------------
  # P1 — Disabled state
  # ---------------------------------------------------------------------------

  test "[P1] renders disabled state with cream-200 fill and ink-3 text" do
    skip "RED PHASE — ButtonComponent not yet implemented"
    render_inline(ButtonComponent.new(label: "Disabled", disabled: true))
    assert_selector "button[disabled]"
  end

  # ---------------------------------------------------------------------------
  # P1 — Type kwarg is forwarded
  # ---------------------------------------------------------------------------

  test "[P1] accepts type kwarg and sets button type attribute" do
    skip "RED PHASE — ButtonComponent not yet implemented"
    render_inline(ButtonComponent.new(label: "Submit Form", type: :submit))
    assert_selector "button[type='submit']"
  end

  # ---------------------------------------------------------------------------
  # P1 — Tap target minimum 44px via CSS (structural: class present)
  # ---------------------------------------------------------------------------

  test "[P1] button element exists for tap-target verification" do
    skip "RED PHASE — ButtonComponent not yet implemented"
    render_inline(ButtonComponent.new(label: "Tap Me"))
    # Tap target ≥44px is enforced through CSS padding.
    # This test verifies the element is rendered so visual QA can confirm size.
    assert_selector "button", text: "Tap Me"
  end

  # ---------------------------------------------------------------------------
  # P2 — Extra html_options are forwarded
  # ---------------------------------------------------------------------------

  test "[P2] forwards data attributes to the rendered element" do
    skip "RED PHASE — ButtonComponent not yet implemented"
    render_inline(ButtonComponent.new(label: "Open", data: { controller: "modal", action: "modal#open" }))
    assert_selector "button[data-controller='modal']"
  end

  # ---------------------------------------------------------------------------
  # P2 — Label passed as kwarg, not hardcoded
  # ---------------------------------------------------------------------------

  test "[P2] label is rendered from kwarg not hardcoded i18n key" do
    skip "RED PHASE — ButtonComponent not yet implemented"
    render_inline(ButtonComponent.new(label: "Custom Label"))
    assert_text "Custom Label"
    # No hardcoded text inside component — label always comes from caller
  end

  # ---------------------------------------------------------------------------
  # P2 — method kwarg passed through for link_to (DELETE, PATCH)
  # ---------------------------------------------------------------------------

  test "[P2] anchor tag forwards method kwarg via data-turbo-method" do
    skip "RED PHASE — ButtonComponent not yet implemented"
    render_inline(ButtonComponent.new(label: "Delete", href: "/conferences/1", method: :delete))
    assert_selector "a[href='/conferences/1'][data-turbo-method='delete']"
  end

  # ---------------------------------------------------------------------------
  # P2 — class kwarg merged into button
  # ---------------------------------------------------------------------------

  test "[P2] additional CSS classes are merged" do
    skip "RED PHASE — ButtonComponent not yet implemented"
    render_inline(ButtonComponent.new(label: "Wide", class: "w-full"))
    assert_selector "button.w-full"
  end
end

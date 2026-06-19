# frozen_string_literal: true

# ATDD Red-Phase Tests — Story 1.2: Core Design System & ViewComponent UI Library
# Subgroup: EmptyStateComponent
#
# TDD RED PHASE: All tests use `skip` until EmptyStateComponent is implemented.
#
# Acceptance Criteria Covered:
#   AC-2: EmptyState layout — one calm line + single primary action, no large illustrations.
#         Accepts message:, action_label:, action_path: kwargs.

require "test_helper"

class EmptyStateComponentTest < ViewComponent::TestCase
  # ---------------------------------------------------------------------------
  # P0 — Renders message and primary action
  # ---------------------------------------------------------------------------

  test "[P0] renders message text" do
    render_inline(EmptyStateComponent.new(
                    message: "No bookings yet",
                    action_label: "Create booking",
                    action_path: "/bookings/new"
                  ))
    assert_text "No bookings yet"
  end

  test "[P0] renders primary action as a link" do
    render_inline(EmptyStateComponent.new(
                    message: "No bookings yet",
                    action_label: "Create booking",
                    action_path: "/bookings/new"
                  ))
    assert_selector "a[href='/bookings/new']", text: "Create booking"
  end

  # ---------------------------------------------------------------------------
  # P0 — No large illustrations (by design)
  # ---------------------------------------------------------------------------

  test "[P0] does not render large illustration images" do
    render_inline(EmptyStateComponent.new(
                    message: "No rooms yet",
                    action_label: "Add room",
                    action_path: "/admin/rooms/new"
                  ))
    # The design spec explicitly forbids large illustrations
    assert_no_selector "img[class*='illustration'], img[class*='hero']"
  end

  # ---------------------------------------------------------------------------
  # P1 — Action uses ButtonComponent (primary variant)
  # ---------------------------------------------------------------------------

  test "[P1] action link has primary button styling" do
    render_inline(EmptyStateComponent.new(
                    message: "No conferences yet",
                    action_label: "Create conference",
                    action_path: "/admin/conferences/new"
                  ))
    assert_selector "a.btn, a.btn-primary"
  end

  # ---------------------------------------------------------------------------
  # P2 — Default message from i18n when no message kwarg
  # ---------------------------------------------------------------------------

  test "[P2] renders default i18n message when no message provided" do
    render_inline(EmptyStateComponent.new(action_label: "Add item", action_path: "/items/new"))
    assert_text I18n.t("components.empty_state.default_message")
  end

  # ---------------------------------------------------------------------------
  # P2 — Renders without action when action_path is nil
  # ---------------------------------------------------------------------------

  test "[P2] renders cleanly without action when action_path is nil" do
    assert_nothing_raised do
      render_inline(EmptyStateComponent.new(message: "Nothing here yet"))
    end
    assert_text "Nothing here yet"
  end
end

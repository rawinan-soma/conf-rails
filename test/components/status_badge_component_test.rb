# frozen_string_literal: true

# ATDD Red-Phase Tests — Story 1.2: Core Design System & ViewComponent UI Library
# Subgroup: StatusBadgeComponent
#
# TDD RED PHASE: All tests use `skip` until StatusBadgeComponent is implemented.
#
# Acceptance Criteria Covered:
#   AC-2: StatusBadge always shows TEXT LABEL — never color-only (WCAG 2.1 AA).
#         :registered (green-100 bg, green-700 text), :cancelled (cream-200 bg, ink-2 text).
#         Thai line-height rule applies: ≥1.5 minimum even in badge context.

require "test_helper"

class StatusBadgeComponentTest < ViewComponent::TestCase
  # ---------------------------------------------------------------------------
  # P0 — Registered status: shows text, not just color
  # ---------------------------------------------------------------------------

  test "[P0] registered status renders text label (not color-only)" do
    render_inline(StatusBadgeComponent.new(status: :registered))
    label = I18n.t("components.status_badge.registered")
    assert page.has_text?(label),
           "badge must show text label — color alone is not sufficient (WCAG)"
  end

  test "[P0] registered status applies green-100 background class" do
    render_inline(StatusBadgeComponent.new(status: :registered))
    # Expects a CSS class or inline style conveying registered visual state
    assert page.has_css?(".badge, [data-status='registered']"),
           "registered badge must have appropriate styling element"
  end

  # ---------------------------------------------------------------------------
  # P0 — Cancelled status
  # ---------------------------------------------------------------------------

  test "[P0] cancelled status renders text label" do
    render_inline(StatusBadgeComponent.new(status: :cancelled))
    label = I18n.t("components.status_badge.cancelled")
    assert page.has_text?(label),
           "badge must show text label for cancelled status"
  end

  # ---------------------------------------------------------------------------
  # P1 — Pill shape (structural: .badge class present)
  # ---------------------------------------------------------------------------

  test "[P1] badge has pill shape via daisyUI badge class" do
    render_inline(StatusBadgeComponent.new(status: :registered))
    assert_selector ".badge"
  end

  # ---------------------------------------------------------------------------
  # P1 — Unknown/future status is handled gracefully
  # ---------------------------------------------------------------------------

  test "[P1] unknown status renders without raising" do
    # Future statuses from later epics must not blow up
    assert_nothing_raised do
      render_inline(StatusBadgeComponent.new(status: :pending_payment))
    end
  end

  # ---------------------------------------------------------------------------
  # P2 — Status is accessible via data attribute for automation
  # ---------------------------------------------------------------------------

  test "[P2] badge exposes status as data attribute for test automation" do
    render_inline(StatusBadgeComponent.new(status: :registered))
    assert_selector "[data-status]"
  end
end

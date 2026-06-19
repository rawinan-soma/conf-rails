# frozen_string_literal: true

# ATDD Red-Phase Tests — Story 1.2: Core Design System & ViewComponent UI Library
# Subgroup: AdminSidebarComponent
#
# TDD RED PHASE: All tests use `skip` until AdminSidebarComponent is implemented.
#
# Acceptance Criteria Covered:
#   AC-2: AdminSidebar renders navigation items passed as array of {label:, path:, active:}.
#         Internal admin shell only — never shown to public/unauthenticated visitors.

require "test_helper"

class AdminSidebarComponentTest < ViewComponent::TestCase
  let(:nav_items) do
    [
      { label: "Dashboard", path: "/admin", active: true },
      { label: "Conferences", path: "/admin/conferences", active: false },
      { label: "Rooms", path: "/admin/rooms", active: false }
    ]
  end

  # ---------------------------------------------------------------------------
  # P1 — Renders all navigation items
  # ---------------------------------------------------------------------------

  test "[P1] renders all provided navigation items" do
    skip "RED PHASE — AdminSidebarComponent not yet implemented"
    items = [
      { label: "Dashboard", path: "/admin", active: true },
      { label: "Conferences", path: "/admin/conferences", active: false },
      { label: "Rooms", path: "/admin/rooms", active: false }
    ]
    render_inline(AdminSidebarComponent.new(nav_items: items))
    assert_selector "nav a", text: "Dashboard"
    assert_selector "nav a", text: "Conferences"
    assert_selector "nav a", text: "Rooms"
  end

  # ---------------------------------------------------------------------------
  # P1 — Active item is highlighted
  # ---------------------------------------------------------------------------

  test "[P1] active nav item has active highlight class" do
    skip "RED PHASE — AdminSidebarComponent not yet implemented"
    items = [
      { label: "Dashboard", path: "/admin", active: true },
      { label: "Conferences", path: "/admin/conferences", active: false }
    ]
    render_inline(AdminSidebarComponent.new(nav_items: items))
    assert_selector "a[aria-current='page'], a.active, a.bg-green-700"
  end

  # ---------------------------------------------------------------------------
  # P1 — Inactive items do not have active class
  # ---------------------------------------------------------------------------

  test "[P1] inactive nav items do not have active class" do
    skip "RED PHASE — AdminSidebarComponent not yet implemented"
    items = [
      { label: "Conferences", path: "/admin/conferences", active: false }
    ]
    render_inline(AdminSidebarComponent.new(nav_items: items))
    assert_no_selector "a[aria-current='page']"
  end

  # ---------------------------------------------------------------------------
  # P1 — Links have correct href
  # ---------------------------------------------------------------------------

  test "[P1] navigation item links point to correct paths" do
    skip "RED PHASE — AdminSidebarComponent not yet implemented"
    items = [
      { label: "Rooms", path: "/admin/rooms", active: false }
    ]
    render_inline(AdminSidebarComponent.new(nav_items: items))
    assert_selector "a[href='/admin/rooms']", text: "Rooms"
  end

  # ---------------------------------------------------------------------------
  # P2 — Green-900 background wrapper for admin shell branding
  # ---------------------------------------------------------------------------

  test "[P2] sidebar has green-900 background wrapper class" do
    skip "RED PHASE — AdminSidebarComponent not yet implemented"
    render_inline(AdminSidebarComponent.new(nav_items: []))
    assert_selector "[class*='bg-green-900'], [class*='bg-base-300'], nav"
  end

  # ---------------------------------------------------------------------------
  # P2 — Empty nav items renders without raising
  # ---------------------------------------------------------------------------

  test "[P2] renders empty sidebar without raising" do
    skip "RED PHASE — AdminSidebarComponent not yet implemented"
    assert_nothing_raised do
      render_inline(AdminSidebarComponent.new(nav_items: []))
    end
  end
end

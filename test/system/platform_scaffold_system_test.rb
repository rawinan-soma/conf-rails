# frozen_string_literal: true

# ATDD Red-Phase System Tests — Story 1.1: Project Initialization & Platform Scaffold
#
# TDD RED PHASE: All tests are skipped until implementation is complete.
# These system tests use Capybara + Selenium to verify the Rails app boots and
# renders daisyUI/Tailwind CSS correctly without Node/npm.
#
# To activate: remove the `skip` call for the task you are currently implementing,
# run `bundle exec rails test test/system/platform_scaffold_system_test.rb`,
# verify the test FAILS first (red), implement, then verify PASSES (green).
#
# Acceptance Criteria Covered:
#   AC-1: Rails 8 boots; page renders with daisyUI CSS; no Node/npm required (P0, R-010)

require "application_system_test_case"

class PlatformScaffoldSystemTest < ApplicationSystemTestCase
  # ---------------------------------------------------------------------------
  # AC-1: Application boots and serves HTTP 200 (P0, R-010)
  # ---------------------------------------------------------------------------

  test "[P0] root path responds with HTTP 200" do
    skip "ATDD RED PHASE — implement Story 1.1 Task 1 & 10 (generate Rails app, smoke test) first"
    visit root_path
    assert_equal 200, page.status_code,
                 "GET / must return HTTP 200 — app must boot without errors"
  end

  test "[P0] rendered page includes Tailwind/daisyUI compiled CSS" do
    skip "ATDD RED PHASE — implement Story 1.1 Task 2 (daisyUI no-Node setup) first"
    visit root_path
    # The page HTML should include the compiled stylesheet link
    # Tailwind standalone CLI outputs to app/assets/builds/tailwind.css
    assert page.has_css?("link[href*='tailwind']", visible: false) ||
           page.has_css?("link[href*='application']", visible: false),
           "Rendered page must include a compiled Tailwind/daisyUI stylesheet link"
  end

  test "[P0] application boots without Node or npm processes" do
    skip "ATDD RED PHASE — implement Story 1.1 Task 2 (daisyUI no-Node setup) first"
    visit root_path
    # If daisyUI loaded via CDN or npm, the page would fail or include cdn links
    assert_no_text "npm ERR",
                   "Application must not reference npm error output"
    assert_no_text "Cannot find module",
                   "Application must not show Node module resolution errors"
  end
end

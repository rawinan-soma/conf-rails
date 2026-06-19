# frozen_string_literal: true

# ATDD Red-Phase Tests — Story 1.2: Core Design System & ViewComponent UI Library
# Subgroup: Design System Integration (Theme, Typography, I18n)
#
# TDD RED PHASE: All tests use `skip` until implementation is complete.
# Remove `skip` task-by-task during implementation.
#
# Acceptance Criteria Covered:
#   AC-1: "Forest & Copper" design tokens & Thai typography
#   AC-2: ViewComponent infrastructure exists
#   AC-3: I18n keys present, th.yml mirrors en.yml key-for-key

require "test_helper"

class DesignSystemTest < ActiveSupport::TestCase
  # ---------------------------------------------------------------------------
  # AC-1: "Forest & Copper" theme tokens in daisyui-theme.mjs
  # ---------------------------------------------------------------------------

  test "[P0] daisyui-theme.mjs defines the forest-copper theme" do
    theme_file = File.read(Rails.root.join("app/assets/tailwind/daisyui-theme.mjs"))
    assert_match "forest-copper", theme_file,
                 "daisyui-theme.mjs must define the 'forest-copper' custom theme"
  end

  test "[P0] theme maps green-700 (#2D6A4F) as primary color" do
    theme_file = File.read(Rails.root.join("app/assets/tailwind/daisyui-theme.mjs"))
    assert_match "#2D6A4F", theme_file,
                 "Theme must define green-700 (#2D6A4F) as the primary color"
  end

  test "[P0] theme maps copper (#B5651D) as secondary color" do
    theme_file = File.read(Rails.root.join("app/assets/tailwind/daisyui-theme.mjs"))
    assert_match "#B5651D", theme_file,
                 "Theme must define copper (#B5651D) as the secondary/accent color"
  end

  test "[P0] theme maps cream (#FAFAF7) as base-100 background" do
    theme_file = File.read(Rails.root.join("app/assets/tailwind/daisyui-theme.mjs"))
    assert_match "#FAFAF7", theme_file,
                 "Theme must define cream (#FAFAF7) as base-100 page background"
  end

  test "[P1] theme maps danger color (#B3261E)" do
    theme_file = File.read(Rails.root.join("app/assets/tailwind/daisyui-theme.mjs"))
    assert_match "#B3261E", theme_file,
                 "Theme must define danger (#B3261E) for destructive actions"
  end

  # ---------------------------------------------------------------------------
  # AC-1: Thai typography in application layout
  # ---------------------------------------------------------------------------

  test "[P0] application layout includes Google Fonts link for Noto Thai fonts" do
    layout = File.read(Rails.root.join("app/views/layouts/application.html.erb"))
    assert_match "fonts.googleapis.com", layout,
                 "application layout must include Google Fonts CDN link for Noto Thai"
    assert_match "Noto", layout,
                 "layout must reference Noto Serif Thai or Noto Sans Thai"
  end

  test "[P0] application CSS defines line-height 1.65 for body" do
    css = File.read(Rails.root.join("app/assets/tailwind/application.css"))
    # Body line-height ≥1.65 is a hard minimum for Thai vowel/tone marks
    assert_match(/line-height:\s*1\.6[5-9]|line-height:\s*[2-9]/, css,
                 "application.css must set body line-height to at least 1.65 for Thai typography")
  end

  test "[P1] application CSS defines minimum font-size 14px" do
    css = File.read(Rails.root.join("app/assets/tailwind/application.css"))
    assert_match(/font-size.*14px|--fs-small:\s*14px/, css,
                 "application.css must enforce 14px as the minimum font size")
  end

  test "[P1] application CSS defines display type scale at 32px" do
    css = File.read(Rails.root.join("app/assets/tailwind/application.css"))
    assert_match(/32px/, css, "application.css must define display size at 32px")
  end

  # ---------------------------------------------------------------------------
  # AC-1: Application layout shell (Task 3)
  # ---------------------------------------------------------------------------

  test "[P1] application layout has theme-color meta tag" do
    layout = File.read(Rails.root.join("app/views/layouts/application.html.erb"))
    assert_match 'name="theme-color"', layout,
                 "layout must include <meta name='theme-color'> for mobile branding"
  end

  test "[P1] application layout includes flash container for ToastComponent" do
    layout = File.read(Rails.root.join("app/views/layouts/application.html.erb"))
    assert_match(/flash|toast|Toast/, layout,
                 "layout must include flash/toast message area")
  end

  # ---------------------------------------------------------------------------
  # AC-2: ViewComponent infrastructure
  # ---------------------------------------------------------------------------

  test "[P0] app/components/ directory exists" do
    assert Dir.exist?(Rails.root.join("app/components")),
           "app/components/ directory must exist"
  end

  test "[P0] ApplicationComponent base class exists and inherits ViewComponent::Base" do
    assert defined?(ApplicationComponent),
           "ApplicationComponent must be defined"
    assert ApplicationComponent < ViewComponent::Base,
           "ApplicationComponent must inherit from ViewComponent::Base"
  end

  test "[P1] ViewComponent initializer exists" do
    assert File.exist?(Rails.root.join("config/initializers/view_component.rb")),
           "config/initializers/view_component.rb must exist"
  end

  # ---------------------------------------------------------------------------
  # AC-2: Admin layout
  # ---------------------------------------------------------------------------

  test "[P1] admin layout file exists" do
    assert File.exist?(Rails.root.join("app/views/layouts/admin.html.erb")),
           "app/views/layouts/admin.html.erb must exist"
  end

  # ---------------------------------------------------------------------------
  # AC-3: I18n key structure
  # ---------------------------------------------------------------------------

  test "[P0] en.yml contains common.cancel key" do
    assert I18n.exists?("common.cancel", :en),
           "en.yml must define 'common.cancel' key"
  end

  test "[P0] en.yml contains common.confirm key" do
    assert I18n.exists?("common.confirm", :en),
           "en.yml must define 'common.confirm' key"
  end

  test "[P0] en.yml contains common.close key" do
    assert I18n.exists?("common.close", :en),
           "en.yml must define 'common.close' key"
  end

  test "[P0] en.yml contains common.loading key" do
    assert I18n.exists?("common.loading", :en),
           "en.yml must define 'common.loading' key"
  end

  test "[P0] en.yml contains components.status_badge.registered key" do
    assert I18n.exists?("components.status_badge.registered", :en),
           "en.yml must define 'components.status_badge.registered'"
  end

  test "[P0] en.yml contains components.status_badge.cancelled key" do
    assert I18n.exists?("components.status_badge.cancelled", :en),
           "en.yml must define 'components.status_badge.cancelled'"
  end

  test "[P0] th.yml mirrors en.yml key-for-key (i18n-tasks health)" do
    # Primary enforcement is CI: `bundle exec i18n-tasks health` passes with 0 errors.
    # This test verifies the sampled keys exist in both locales.
    sampled_keys = %w[
      common.cancel common.confirm common.close common.loading
      components.status_badge.registered components.status_badge.cancelled
      components.modal.close_label components.toast.success_prefix
    ]
    sampled_keys.each do |key|
      assert I18n.exists?(key, :th),
             "th.yml must mirror key '#{key}' from en.yml"
    end
  end

  test "[P1] en.yml contains components.modal.close_label key" do
    assert I18n.exists?("components.modal.close_label", :en),
           "en.yml must define 'components.modal.close_label'"
  end

  test "[P1] en.yml contains components.toast.success_prefix key" do
    assert I18n.exists?("components.toast.success_prefix", :en),
           "en.yml must define 'components.toast.success_prefix'"
  end

  test "[P1] en.yml contains components.toast.error_prefix key" do
    assert I18n.exists?("components.toast.error_prefix", :en),
           "en.yml must define 'components.toast.error_prefix'"
  end

  test "[P1] en.yml contains components.empty_state.default_message key" do
    assert I18n.exists?("components.empty_state.default_message", :en),
           "en.yml must define 'components.empty_state.default_message'"
  end

  # ---------------------------------------------------------------------------
  # AC-3: No hardcoded user-visible strings in component templates
  # ---------------------------------------------------------------------------

  test "[P1] no hardcoded user-visible strings in component .html.erb files" do
    component_erb_files = Dir.glob(Rails.root.join("app/components/**/*.html.erb"))
    assert component_erb_files.any?,
           "There must be component .html.erb templates in app/components/"

    component_erb_files.each do |file|
      content = File.read(file)
      # Strings that appear directly as content (not i18n calls) are forbidden.
      # This is a heuristic check — CI's i18n-tasks is the definitive gate.
      refute_match(/>[\s]*[A-Z][a-z]+ [a-z]/, content,
                   "#{File.basename(file)} appears to contain hardcoded English text — use t('.key')")
    end
  end

  # ---------------------------------------------------------------------------
  # AC-1: CSS spacing/radius/elevation custom properties
  # ---------------------------------------------------------------------------

  test "[P2] application.css defines --radius-sm, --radius-md, --radius-lg custom properties" do
    css = File.read(Rails.root.join("app/assets/tailwind/application.css"))
    assert_match "--radius-sm", css, "Must define --radius-sm (6px)"
    assert_match "--radius-md", css, "Must define --radius-md (10px)"
    assert_match "--radius-lg", css, "Must define --radius-lg (16px)"
  end

  test "[P2] application.css defines --shadow-1, --shadow-2, --shadow-3 custom properties" do
    css = File.read(Rails.root.join("app/assets/tailwind/application.css"))
    assert_match "--shadow-1", css, "Must define --shadow-1"
    assert_match "--shadow-2", css, "Must define --shadow-2"
    assert_match "--shadow-3", css, "Must define --shadow-3"
  end
end

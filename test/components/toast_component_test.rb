# frozen_string_literal: true

# ATDD Red-Phase Tests — Story 1.2: Core Design System & ViewComponent UI Library
# Subgroup: ToastComponent
#
# TDD RED PHASE: All tests use `skip` until ToastComponent is implemented.
#
# Acceptance Criteria Covered:
#   AC-2: Toast shows icon or prefix word in addition to color (no color-alone meaning,
#         WCAG 2.1 AA). Accepts message:, type: (:success, :error, :info) kwargs.

require "test_helper"

class ToastComponentTest < ViewComponent::TestCase
  # ---------------------------------------------------------------------------
  # P0 — No color-alone meaning: icon or text prefix alongside color
  # ---------------------------------------------------------------------------

  test "[P0] success toast shows prefix word or icon (not color-only)" do
    render_inline(ToastComponent.new(message: "Conference saved.", type: :success))
    # Must show a prefix like "Success" or an icon element, not rely on color alone
    has_prefix = page.has_text?(I18n.t("components.toast.success_prefix"))
    has_icon = page.has_css?("[aria-hidden='true'], svg, .icon")
    assert has_prefix || has_icon,
           "success toast must convey meaning via text prefix or icon, not color alone"
  end

  test "[P0] error toast shows prefix word or icon (not color-only)" do
    render_inline(ToastComponent.new(message: "Failed to save.", type: :error))
    has_prefix = page.has_text?(I18n.t("components.toast.error_prefix"))
    has_icon = page.has_css?("[aria-hidden='true'], svg, .icon")
    assert has_prefix || has_icon,
           "error toast must convey meaning via text prefix or icon, not color alone"
  end

  # ---------------------------------------------------------------------------
  # P0 — Message is rendered
  # ---------------------------------------------------------------------------

  test "[P0] renders the message kwarg as text" do
    render_inline(ToastComponent.new(message: "Conference created successfully.", type: :success))
    assert_text "Conference created successfully."
  end

  # ---------------------------------------------------------------------------
  # P1 — Type variants render without error
  # ---------------------------------------------------------------------------

  test "[P1] info type renders without raising" do
    assert_nothing_raised do
      render_inline(ToastComponent.new(message: "Reminder sent.", type: :info))
    end
    assert_text "Reminder sent."
    # info type maps to info_prefix key (see ToastComponent::TYPE_PREFIXES)
    assert page.has_text?(I18n.t("components.toast.info_prefix")),
           "info toast should render a prefix text (maps to info_prefix key)"
  end

  # ---------------------------------------------------------------------------
  # P1 — Alert class present (positioning is handled by #flash-container in the layout)
  # ---------------------------------------------------------------------------

  test "[P1] toast renders as an alert element" do
    render_inline(ToastComponent.new(message: "Saved.", type: :success))
    # The .toast daisyUI class is NOT applied to the component itself — it would force
    # position:fixed on each toast, breaking stacking inside the layout's #flash-container.
    # Positioning is handled by the fixed #flash-container wrapper in the layout.
    assert_selector ".alert, [data-controller='toast']"
  end

  # ---------------------------------------------------------------------------
  # P2 — Auto-dismiss controller hook
  # ---------------------------------------------------------------------------

  test "[P2] toast element has Stimulus controller attribute for auto-dismiss" do
    render_inline(ToastComponent.new(message: "Saved.", type: :success))
    # Stimulus controller for auto-dismiss via setTimeout
    assert_selector "[data-controller]"
  end
end

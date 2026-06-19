# frozen_string_literal: true

# ATDD Red-Phase Tests — Story 1.2: Core Design System & ViewComponent UI Library
# Subgroup: FormFieldComponent
#
# TDD RED PHASE: All tests use `skip` until FormFieldComponent is implemented.
#
# Acceptance Criteria Covered:
#   AC-2: Form fields render with always-visible labels, visible focus rings (≥2px green-500),
#         no color-alone meaning, and proper error state (WCAG 2.1 AA).

require "test_helper"

class FormFieldComponentTest < ViewComponent::TestCase
  # ---------------------------------------------------------------------------
  # P0 — Label is always visible above the input
  # ---------------------------------------------------------------------------

  test "[P0] renders visible label above input" do
    render_inline(FormFieldComponent.new(attribute: :name, label: "Full Name"))
    assert_selector "label", text: "Full Name"
    assert_selector "input"
    # Label must appear before input (not placeholder-only)
    html = page.native.to_html
    label_pos = html.index("<label")
    input_pos = html.index("<input")
    assert label_pos < input_pos, "label must appear before input in DOM order"
  end

  test "[P0] does not rely on placeholder as the only label (WCAG)" do
    render_inline(FormFieldComponent.new(attribute: :email, label: "Email"))
    assert_selector "label", text: "Email"
    # The component must not omit the <label> element
    assert_no_selector "[placeholder]:not([aria-label]):not([id])"
  end

  # ---------------------------------------------------------------------------
  # P0 — Error state
  # ---------------------------------------------------------------------------

  test "[P0] renders error message below field when error kwarg provided" do
    render_inline(FormFieldComponent.new(attribute: :email, label: "Email",
                                         error: "can't be blank"))
    assert_selector "[aria-describedby]"
    assert_text "can't be blank"
  end

  test "[P0] input references error message via aria-describedby" do
    render_inline(FormFieldComponent.new(attribute: :email, label: "Email",
                                         error: "is invalid"))
    input = page.find("input")
    describedby = input["aria-describedby"]
    assert describedby.present?, "input must have aria-describedby pointing to error"
    assert page.has_css?("##{describedby}"), "element with id=#{describedby} must exist"
  end

  # ---------------------------------------------------------------------------
  # P1 — Required field indicator
  # ---------------------------------------------------------------------------

  test "[P1] required field shows asterisk indicator after label" do
    render_inline(FormFieldComponent.new(attribute: :name, label: "Name", required: true))
    assert_text "*"
    assert_selector "input[required]"
  end

  # ---------------------------------------------------------------------------
  # P1 — Hint text
  # ---------------------------------------------------------------------------

  test "[P1] renders hint text below label when hint kwarg provided" do
    render_inline(FormFieldComponent.new(attribute: :name, label: "Name",
                                         hint: "Enter your full legal name"))
    assert_text "Enter your full legal name"
  end

  # ---------------------------------------------------------------------------
  # P1 — Label is associated with input (for accessibility)
  # ---------------------------------------------------------------------------

  test "[P1] label for attribute matches input id" do
    render_inline(FormFieldComponent.new(attribute: :email, label: "Email"))
    label = page.find("label")
    input = page.find("input")
    assert_equal input["id"], label["for"],
                 "label[for] must match input[id] for screen reader association"
  end

  # ---------------------------------------------------------------------------
  # P2 — No error state (clean render)
  # ---------------------------------------------------------------------------

  test "[P2] renders cleanly without error when no error kwarg given" do
    render_inline(FormFieldComponent.new(attribute: :name, label: "Name"))
    assert_no_selector ".field-error, .text-danger, [aria-invalid='true']"
  end

  # ---------------------------------------------------------------------------
  # P2 — Error state applies danger styling class
  # ---------------------------------------------------------------------------

  test "[P2] error state applies danger border class to input" do
    render_inline(FormFieldComponent.new(attribute: :email, label: "Email",
                                         error: "is invalid"))
    # Danger border class expected on the wrapper or input
    assert page.has_css?(".input-error, [aria-invalid='true']"),
           "error state must mark input with .input-error or aria-invalid"
  end
end

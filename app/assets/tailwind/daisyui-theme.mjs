/** Forest & Copper theme — daisyUI v5 custom theme plugin */

// packages/daisyui/functions/plugin.js
var plugin = {
  withOptions: (pluginFunction, configFunction = () => ({})) => {
    const optionsFunction = (options) => {
      const handler = pluginFunction(options);
      const config = configFunction(options);
      return { handler, config };
    };
    optionsFunction.__isOptionsFunction = true;
    return optionsFunction;
  }
};

// Forest & Copper theme tokens
var forestCopperTheme = {
  name: "forest-copper",
  default: true,
  "color-scheme": "light",
  "--color-primary": "#2D6A4F",
  "--color-primary-content": "#FFFFFF",
  "--color-secondary": "#B5651D",
  "--color-secondary-content": "#FFFFFF",
  "--color-accent": "#E8A96A",
  "--color-accent-content": "#1C1C1C",
  "--color-neutral": "#1B4332",
  "--color-neutral-content": "#FAFAF7",
  "--color-base-100": "#FAFAF7",
  "--color-base-200": "#F0EDE6",
  "--color-base-300": "#E8E3DA",
  "--color-base-content": "#1C1C1C",
  "--color-info": "#40916C",
  "--color-info-content": "#FFFFFF",
  "--color-success": "#2D6A4F",
  "--color-success-content": "#FFFFFF",
  "--color-warning": "#B5651D",
  "--color-warning-content": "#FFFFFF",
  "--color-error": "#B3261E",
  "--color-error-content": "#FFFFFF",
  "--radius-selector": "0.625rem",
  "--radius-field": "0.375rem",
  "--radius-box": "1rem",
  "--size-selector": "0.25rem",
  "--size-field": "0.25rem",
  "--border": "1px",
  "--depth": "0",
  "--noise": "0"
};

var theme_default = plugin.withOptions((options = forestCopperTheme) => {
  return ({ addBase }) => {
    const {
      name = "forest-copper",
      default: isDefault = true,
      prefersdark = false,
      "color-scheme": colorScheme = "light",
      root = ":root",
      ...customThemeTokens
    } = options;
    let selector = `${root}:has(input.theme-controller[value=${name}]:checked),[data-theme="${name}"]`;
    if (isDefault) {
      selector = `:where(${root}),${selector}`;
    }
    const baseStyles = {
      [selector]: {
        "color-scheme": colorScheme,
        ...customThemeTokens
      }
    };
    if (prefersdark) {
      const darkSelector = root === ":root" ? ":root:not([data-theme])" : `${root}:not([data-theme])`;
      addBase({
        "@media (prefers-color-scheme: dark)": {
          [darkSelector]: baseStyles[selector]
        }
      });
    }
    addBase(baseStyles);
  };
});
export {
  theme_default as default
};

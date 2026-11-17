module LayoutChecks
  TAP_TARGET_SCRIPT = <<~JS.freeze
    return Array.from(document.querySelectorAll("header a, header button, main a, main button, main input, main select, main textarea"))
      .filter((element) => {
        if (element.type === "hidden") return false;
        const rect = element.getBoundingClientRect();
        if (rect.width === 0 || rect.height === 0) return false;
        if (getComputedStyle(element).visibility === "hidden") return false;
        if (element.tagName === "A" && getComputedStyle(element).display === "inline") {
          const container = element.parentElement;
          if (container && container.textContent.trim() !== element.textContent.trim()) return false;
        }
        const target = ["checkbox", "radio"].includes(element.type) && element.labels.length > 0 ? element.labels[0] : element;
        return target.getBoundingClientRect().height < 44;
      })
      .map((element) => `${element.tagName.toLowerCase()} "${(element.textContent || element.name || element.id).trim()}" ${Math.round(element.getBoundingClientRect().height)}px`);
  JS

  def resize_viewport(width, height = 900)
    page.driver.browser.manage.window.resize_to(width, height)
  end

  def horizontal_overflow
    page.evaluate_script("document.documentElement.scrollWidth - window.innerWidth")
  end

  def small_tap_targets
    page.execute_script(TAP_TARGET_SCRIPT)
  end
end

RSpec.configure do |config|
  config.include LayoutChecks, type: :system
end

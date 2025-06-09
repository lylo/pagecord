// Test script to validate Tagify integration
// This can be run in the browser console to test Tagify functionality

console.log("Testing Tagify integration...");

// Check if Tagify is available
try {
  const tagifyModule = await import("@yaireo/tagify");
  console.log("✅ Tagify module loaded successfully:", tagifyModule);
} catch (error) {
  console.error("❌ Failed to load Tagify module:", error);
}

// Check if our Stimulus controller is registered
const application = window.Stimulus;
if (application && application.controllers.has("tags-input")) {
  console.log("✅ Tags input Stimulus controller is registered");
} else {
  console.log("❌ Tags input Stimulus controller not found");
}

// Check if Tagify CSS is loaded
const tagifyStyles = Array.from(document.styleSheets).some(sheet => {
  try {
    return Array.from(sheet.cssRules || []).some(rule =>
      rule.selectorText && rule.selectorText.includes('tagify')
    );
  } catch (e) {
    return false;
  }
});

if (tagifyStyles) {
  console.log("✅ Tagify CSS styles are loaded");
} else {
  console.log("❌ Tagify CSS styles not found");
}

console.log("Tagify integration test complete!");

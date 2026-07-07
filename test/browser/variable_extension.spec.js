import { test, expect } from "@playwright/test"

// Drives the real editor through the same import-map setup an importmap-rails
// host uses (see fixture/index.html): the lexxy gem's self-contained lexxy.js
// plus the vendored extension. No bundler, no Rails.
test.beforeEach(async ({ page }) => {
  await page.goto("/")
})

const editable = (page) => page.locator("lexxy-editor [contenteditable='true']")
const chip = (page) => page.locator("lexxy-editor action-text-attachment .lexxy-variable")

test("typing the {{ trigger opens the prompt and inserting swaps it for a chip", async ({ page }) => {
  // Regression test for the replaceTextBackUntil patch: stock Lexxy (through
  // 0.9.23) anchors the replacement on the trigger's first character with
  // lastIndexOf, so a two-char "{{" trigger silently aborts the insert.
  await editable(page).click()
  await editable(page).pressSequentially("Hello {{")

  const menu = page.locator(".lexxy-prompt-menu--visible")
  await expect(menu).toBeVisible()
  await expect(menu.locator(".lexxy-prompt-menu__item")).toHaveCount(2)

  await menu.locator(".lexxy-prompt-menu__item", { hasText: "Company" }).click()

  await expect(chip(page)).toHaveAttribute("data-lexxy-key", "company")
  await expect(editable(page)).toContainText("Hello")
  await expect(editable(page)).not.toContainText("{{")
})

test("the prompt filters as you type and inserts with Enter", async ({ page }) => {
  await editable(page).click()
  await editable(page).pressSequentially("{{first")

  const menu = page.locator(".lexxy-prompt-menu--visible")
  await expect(menu.locator(".lexxy-prompt-menu__item")).toHaveCount(1)

  await page.keyboard.press("Enter")

  await expect(chip(page)).toHaveAttribute("data-lexxy-key", "first_name")
  await expect(editable(page)).not.toContainText("{{")
})

test("the toolbar dropdown lists the catalog and inserts a chip", async ({ page }) => {
  await page.locator("button[name='variable']").click()

  const items = page.locator(".lexxy-variables-menu__item")
  await expect(items).toHaveCount(2)

  await items.filter({ hasText: "First name" }).click()

  await expect(chip(page)).toHaveAttribute("data-lexxy-key", "first_name")
})

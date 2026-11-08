import { test, expect } from "@playwright/test"
import { chip, editable } from "./helpers.js"

test.beforeEach(async ({ page }) => {
  await page.goto("/")
})

test("chips follow Lexxy's theme unless the chip variable overrides it", async ({ page }) => {
  await page.addStyleTag({ content: ":root { --lexxy-color-selected: rgb(1, 2, 3) }" })

  await insertChip(page)

  await expect(chip(page)).toHaveCSS("background-color", "rgb(1, 2, 3)")

  await page.addStyleTag({ content: ":root { --lexxy-variable-background: rgb(4, 5, 6) }" })

  await expect(chip(page)).toHaveCSS("background-color", "rgb(4, 5, 6)")
})

test("a selected chip keeps its shape and takes Lexxy's selection colors", async ({ page }) => {
  await page.addStyleTag({ content: `
    :root { --lexxy-color-accent-dark: rgb(20, 30, 40) }
    .lexxy-variable { background: rgb(4, 5, 6); border-radius: 999px }
  ` })
  await insertChip(page)

  await selectChip(page)

  await expect(chip(page)).toHaveCSS("background-color", "rgb(20, 30, 40)")
  await expect(chip(page)).toHaveCSS("border-radius", "999px")
  await expect(page.locator("lexxy-editor action-text-attachment.node--selected")).toHaveCSS("background-color", "rgba(0, 0, 0, 0)")
})

test("selected chip colors can be overridden", async ({ page }) => {
  await page.addStyleTag({ content: `
    :root {
      --lexxy-variable-selected-background: rgb(50, 60, 70);
      --lexxy-variable-selected-color: rgb(80, 90, 100);
    }
  ` })
  await insertChip(page)

  await selectChip(page)

  await expect(chip(page)).toHaveCSS("background-color", "rgb(50, 60, 70)")
  await expect(chip(page)).toHaveCSS("color", "rgb(80, 90, 100)")
})

test("the toolbar dropdown opens inside the editor", async ({ page }) => {
  await page.locator("button[name='variable']").click()

  const menu = await page.locator(".lexxy-variables-menu").boundingBox()
  const editor = await page.locator("lexxy-editor").boundingBox()
  expect(menu.x).toBeGreaterThanOrEqual(editor.x)
  expect(menu.x + menu.width).toBeLessThanOrEqual(editor.x + editor.width)
})

test("only the variables prompt is widened past Lexxy's cap", async ({ page }) => {
  const popup = page.locator(".lexxy-prompt-menu--visible")

  await editable(page).click()
  await editable(page).pressSequentially("{{")

  await expect(popup).toHaveCSS("max-width", /384px/)

  await page.keyboard.press("Escape")
  await editable(page).pressSequentially(" @")

  await expect(popup).toBeVisible()
  await expect(popup).not.toHaveCSS("max-width", /384px/)
})

test("Lexxy's variables can be set on one of the gem's classes", async ({ page }) => {
  await page.addStyleTag({ content: `
    .lexxy-variables-menu { --lexxy-color-canvas: rgb(7, 8, 9) }
    .lexxy-prompt-menu:has(.lexxy-variables-option) { --lexxy-color-canvas: rgb(10, 11, 12) }
  ` })

  await page.locator("button[name='variable']").click()

  await expect(page.locator(".lexxy-variables-menu")).toHaveCSS("background-color", "rgb(7, 8, 9)")
  await expect(page.locator("button[name='variable']")).not.toHaveCSS("background-color", "rgb(7, 8, 9)")

  await page.keyboard.press("Escape")
  await editable(page).click()
  await editable(page).pressSequentially("{{")

  await expect(page.locator(".lexxy-prompt-menu--visible")).toHaveCSS("background-color", "rgb(10, 11, 12)")
})

async function insertChip(page) {
  await editable(page).click()
  await editable(page).pressSequentially("{{")
  await expect(page.locator(".lexxy-prompt-menu--visible")).toBeVisible()
  await page.keyboard.press("Enter")
  await expect(chip(page)).toBeVisible()
}

async function selectChip(page) {
  await page.locator("lexxy-editor action-text-attachment").first().click()
  await expect(page.locator("lexxy-editor action-text-attachment.node--selected")).toHaveCount(1)
}

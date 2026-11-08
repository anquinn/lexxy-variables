export function editable(page) {
  return page.locator("lexxy-editor [contenteditable='true']")
}

export function chip(page) {
  return page.locator("lexxy-editor action-text-attachment .lexxy-variable")
}

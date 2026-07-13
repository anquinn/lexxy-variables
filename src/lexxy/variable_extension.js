import * as Lexxy from "@37signals/lexxy"

const VARIABLE_CONTENT_TYPE = "application/vnd.actiontext.variable"

const ICON = `
  <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none"
       stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
    <path stroke="none" d="M0 0h24v24H0z" fill="none" />
    <path d="M7 4a2 2 0 0 0 -2 2v3a2 3 0 0 1 -2 3a2 3 0 0 1 2 3v3a2 2 0 0 0 2 2" />
    <path d="M17 4a2 2 0 0 1 2 2v3a2 3 0 0 0 2 3a2 3 0 0 0 -2 3v3a2 2 0 0 1 -2 2" />
  </svg>`

// Adds an "Insert variable" toolbar dropdown fed by the same server-rendered
// <lexxy-prompt name="variable"> items that power the typed "{{" trigger. The
// prompt items are produced by the host app, so this extension is content-agnostic.
export default class VariableExtension extends Lexxy.Extension {
  get enabled() {
    return this.editorElement.supportsRichText && this.promptItems.length > 0
  }

  get allowedElements() {
    return [ { tag: "span", attributes: [ "data-lexxy-key", "class" ] } ]
  }

  initializeToolbar(toolbar) {
    const dropdown = document.createElement("lexxy-toolbar-dropdown")
    dropdown.className = "lexxy-editor__toolbar-dropdown"
    dropdown.innerHTML = `
      <button data-dropdown-trigger class="lexxy-editor__toolbar-button lexxy-editor__toolbar-button--chevron"
              type="button" name="variable" title="Insert variable" aria-haspopup="menu" aria-expanded="false">${ICON}</button>
      <div data-dropdown-panel role="menu" class="lexxy-variables-menu" aria-label="Variables" hidden></div>`

    const panel = dropdown.querySelector("[data-dropdown-panel]")
    for (const item of this.promptItems) {
      panel.appendChild(this.#menuButtonFor(item, dropdown))
    }

    toolbar.appendChild(dropdown)
  }

  get promptItems() {
    return Array.from(this.editorElement.querySelectorAll("lexxy-prompt[name='variable'] lexxy-prompt-item"))
  }

  #menuButtonFor(item, dropdown) {
    const button = document.createElement("button")
    button.type = "button"
    button.className = "lexxy-variables-menu__item"
    button.setAttribute("role", "menuitem")
    button.append(item.querySelector("template[type='menu']").content.cloneNode(true))
    button.addEventListener("click", (event) => {
      event.preventDefault()
      dropdown.close()
      this.#insert(item)
    })
    return button
  }

  #insert(item) {
    const template = item.querySelector("template[type='editor']")
    const attachment = document.createElement("action-text-attachment")
    attachment.setAttribute("sgid", item.getAttribute("sgid"))
    attachment.setAttribute("content-type", template.getAttribute("content-type") || VARIABLE_CONTENT_TYPE)
    attachment.setAttribute("content", template.innerHTML.trim())
    this.editorElement.contents.insertHtml(attachment.outerHTML)
  }
}

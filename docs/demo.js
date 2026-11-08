import * as Lexxy from "@37signals/lexxy"
import VariableExtension from "lexxy-variables"

Lexxy.configure({ global: { extensions: [ VariableExtension ] } })

const VARIABLE_TYPE = "application/vnd.actiontext.variable"

const CATALOG = [
  { key: "first_name", name: "First name" },
  { key: "team", name: "Team" },
  { key: "task", name: "Task" },
  { key: "due", name: "Due" }
]

const PEOPLE = [
  { first_name: "Ada", team: "Engines", task: "Note G", due: "Monday" },
  { first_name: "Grace", team: "Compilers", task: "Find the bug", due: "Tuesday" },
  { first_name: "Linus", team: "Kernels", task: "Review patches", due: "tomorrow" }
]

const STARTING_CONTENT = `
  <p>Hi [[first_name]]!</p>
  <p>Welcome to [[team]]. Your first task is <strong>[[task]]</strong>, due [[due]].</p>
  <p><strong>Try me.</strong> Type {{ anywhere, or pick from the menu above.</p>`

const editorHost = document.querySelector("[data-demo-editor]")
const hash = document.querySelector("[data-demo-hash]")
const output = document.querySelector("[data-demo-output]")
const tabs = document.querySelectorAll("[data-person]")

const escapeHtml = (text) => String(text).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c])

const chipHtml = ({ key, name }) =>
  `<span class="lexxy-variable" data-lexxy-key="${escapeHtml(key)}">${escapeHtml(name)}</span>`

// The same markup the gem's lexxy_variables_prompt helper renders.
function promptHtml() {
  const items = CATALOG.map((variable) => `
    <lexxy-prompt-item search="${escapeHtml(`${variable.name} ${variable.key}`)}" sgid="demo-${escapeHtml(variable.key)}">
      <template type="menu">
        <span class="lexxy-variables-option">
          <span class="lexxy-variables-option__header">
            <span class="lexxy-variables-option__name">${escapeHtml(variable.name)}</span>
          </span>
          <code class="lexxy-variables-option__code">{{ ${escapeHtml(variable.key)} }}</code>
        </span>
      </template>
      <template type="editor" content-type="${VARIABLE_TYPE}">${chipHtml(variable)}</template>
    </lexxy-prompt-item>`).join("")

  return `<lexxy-prompt trigger="{{" name="variable" empty-results="No variables">${items}</lexxy-prompt>`
}

// Saved content stores each chip as an attachment, so build the starting
// value the way Action Text would hand it back.
function startingValue() {
  return STARTING_CONTENT.replace(/\[\[(\w+)\]\]/g, (_, key) => {
    const attachment = document.createElement("action-text-attachment")
    attachment.setAttribute("sgid", `demo-${key}`)
    attachment.setAttribute("content-type", VARIABLE_TYPE)
    attachment.setAttribute("content", chipHtml(CATALOG.find((v) => v.key === key)))
    return attachment.outerHTML
  })
}

function renderHash(values) {
  const width = Math.max(...Object.keys(values).map((key) => key.length)) + 1
  const lines = Object.entries(values).map(([ key, value ], index, all) => {
    const comma = index < all.length - 1 ? "," : ""
    return `  ${`${key}:`.padEnd(width)} <span class="s">"${escapeHtml(value)}"</span>${comma}`
  })

  hash.innerHTML = [
    `<span class="c"># pass any hash at render time</span>`,
    "@body = record.body.with_variables(",
    ...lines,
    ")"
  ].join("\n")
}

function readHash() {
  const values = {}
  for (const [ , key, value ] of hash.innerText.matchAll(/([\w.]+)\s*:\s*"([^"]*)"/g)) values[key] = value
  return values
}

function keyOf(attachment) {
  const content = attachment.getAttribute("content")
  const source = content ? new DOMParser().parseFromString(content, "text/html") : attachment
  return source.querySelector("[data-lexxy-key]")?.getAttribute("data-lexxy-key")
}

// A small stand-in for with_variables: swap each variable attachment for its
// value as a text node, so values can never add markup.
function renderOutput() {
  const values = readHash()
  const doc = new DOMParser().parseFromString(`<div>${editor.value || ""}</div>`, "text/html")

  for (const attachment of doc.querySelectorAll(`action-text-attachment[content-type="${VARIABLE_TYPE}"]`)) {
    const key = keyOf(attachment)
    const filled = key in values
    const node = doc.createElement(filled ? "mark" : "span")
    node.className = filled ? "filled" : "missing"
    node.textContent = filled ? values[key] : `{{ ${key} }}`
    attachment.replaceWith(node)
  }

  output.innerHTML = doc.body.firstChild.innerHTML
}

function pick(index) {
  tabs.forEach((tab) => tab.setAttribute("aria-pressed", String(Number(tab.dataset.person) === index)))
  renderHash(PEOPLE[index])
  renderOutput()
}

const editor = document.createElement("lexxy-editor")
editor.className = "lexxy-content"
editor.setAttribute("placeholder", "Write something, then type {{")
editor.setAttribute("value", startingValue())
editor.innerHTML = promptHtml()
editorHost.append(editor)

renderHash(PEOPLE[0])
editor.addEventListener("lexxy:change", renderOutput)
editor.addEventListener("lexxy:initialize", renderOutput)
hash.addEventListener("input", renderOutput)
tabs.forEach((tab) => tab.addEventListener("click", () => pick(Number(tab.dataset.person))))
renderOutput()

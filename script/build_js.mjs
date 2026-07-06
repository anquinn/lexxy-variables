// Copies the single JS + CSS sources to vendor/ so importmap / asset-pipeline
// hosts get the same files the npm package ships. Run after editing src/.
import { copyFileSync, mkdirSync } from "node:fs"
import { dirname, resolve } from "node:path"
import { fileURLToPath } from "node:url"

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..")

const copies = [
  [ "src/lexxy/variable_extension.js", "vendor/javascript/lexxy_variables.js" ],
  [ "src/styles/lexxy_variables.css", "vendor/stylesheets/lexxy_variables.css" ]
]

for (const [ from, to ] of copies) {
  const src = resolve(root, from)
  const dest = resolve(root, to)
  mkdirSync(dirname(dest), { recursive: true })
  copyFileSync(src, dest)
  console.log(`copied ${from} -> ${to}`)
}

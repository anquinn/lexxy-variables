// Static server for the browser test fixture. Serves the repo root (vendored
// extension JS/CSS) plus the lexxy gem's self-contained lexxy.js and
// stylesheets, so the fixture's import map mirrors a real importmap-rails host
// with no Rails app in the loop.
import { createServer } from "node:http"
import { readFile } from "node:fs/promises"
import { execSync } from "node:child_process"
import { join, normalize, extname, resolve, dirname } from "node:path"
import { fileURLToPath } from "node:url"

const root = resolve(dirname(fileURLToPath(import.meta.url)), "../..")
const lexxyGemDir = execSync("bundle show lexxy", { cwd: root, encoding: "utf8" }).trim()
const port = Number(process.env.PORT || 4173)

const TYPES = {
  ".html": "text/html",
  ".js": "text/javascript",
  ".css": "text/css",
  ".map": "application/json",
  ".svg": "image/svg+xml"
}

function pathFor(url) {
  if (url === "/") return join(root, "test/browser/fixture/index.html")
  if (url === "/lexxy.js" || url === "/lexxy.js.map") return join(lexxyGemDir, "app/assets/javascript", url)
  if (url.startsWith("/lexxy-css/")) return join(lexxyGemDir, "app/assets/stylesheets", url.slice("/lexxy-css/".length))
  return join(root, url)
}

createServer(async (req, res) => {
  const url = decodeURIComponent(new URL(req.url, "http://localhost").pathname)
  const path = normalize(pathFor(url))
  if (!path.startsWith(root) && !path.startsWith(lexxyGemDir)) {
    res.writeHead(403)
    res.end()
    return
  }

  try {
    const body = await readFile(path)
    res.writeHead(200, { "content-type": TYPES[extname(path)] || "application/octet-stream" })
    res.end(body)
  } catch {
    res.writeHead(404)
    res.end("not found")
  }
}).listen(port, () => console.log(`fixture server on http://localhost:${port}`))

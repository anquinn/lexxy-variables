// Local release bookkeeping. Bumps both version files in lockstep, syncs
// vendor/, dates the changelog entry, runs the checks, then commits and tags.
// Publishing happens in CI (.github/workflows/release.yml) when the tag is
// pushed. Usage: npm run release -- <patch|minor|major|X.Y.Z|current>
import { execSync } from "node:child_process"
import { readFileSync, writeFileSync } from "node:fs"
import { dirname, resolve } from "node:path"
import { fileURLToPath } from "node:url"

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..")

function capture(command) {
  return execSync(command, { cwd: root, encoding: "utf8" }).trim()
}

function fail(message) {
  console.error(`release: ${message}`)
  process.exit(1)
}

function step(command) {
  console.log(`\n> ${command}`)
  try {
    execSync(command, { cwd: root, stdio: "inherit" })
  } catch {
    fail(`"${command}" failed. Version changes are left in the working tree, undo them with "git restore ." if needed.`)
  }
}

const mode = process.argv[2]
if (!mode) fail("usage: npm run release -- <patch|minor|major|X.Y.Z|current>")

if (capture("git status --porcelain") !== "") fail("working tree is dirty. Commit or stash first.")
if (capture("git rev-parse --abbrev-ref HEAD") !== "main") fail("releases are cut from main.")

const packagePath = resolve(root, "package.json")
const versionPath = resolve(root, "lib/lexxy_variables/version.rb")
const changelogPath = resolve(root, "CHANGELOG.md")

const packageJson = JSON.parse(readFileSync(packagePath, "utf8"))
const versionRb = readFileSync(versionPath, "utf8")
const currentVersion = versionRb.match(/VERSION = "([^"]+)"/)?.[1]
if (!currentVersion) fail("could not read VERSION from lib/lexxy_variables/version.rb")
if (currentVersion !== packageJson.version) {
  fail(`version.rb (${currentVersion}) and package.json (${packageJson.version}) disagree. Fix that first.`)
}

let version
if (mode === "current") {
  version = currentVersion
} else if (/^\d+\.\d+\.\d+$/.test(mode)) {
  version = mode
} else if ([ "major", "minor", "patch" ].includes(mode)) {
  const [ major, minor, patch ] = currentVersion.split(".").map(Number)
  version = {
    major: `${major + 1}.0.0`,
    minor: `${major}.${minor + 1}.0`,
    patch: `${major}.${minor}.${patch + 1}`
  }[mode]
} else {
  fail(`unknown argument "${mode}". Expected patch, minor, major, current or X.Y.Z.`)
}

const tag = `v${version}`
if (capture(`git tag --list ${tag}`) !== "") fail(`tag ${tag} already exists.`)

// The changelog section is written by hand before releasing. The script only
// dates it, so a release can never go out undocumented.
const changelog = readFileSync(changelogPath, "utf8")
const heading = new RegExp(`^## ${version.replaceAll(".", "\\.")}( \\(\\d{4}-\\d{2}-\\d{2}\\))?$`, "m")
if (!heading.test(changelog)) fail(`CHANGELOG.md has no "## ${version}" section. Write one first.`)
const today = new Date().toISOString().slice(0, 10)
writeFileSync(changelogPath, changelog.replace(heading, `## ${version} (${today})`))

if (version !== currentVersion) {
  packageJson.version = version
  writeFileSync(packagePath, JSON.stringify(packageJson, null, 2) + "\n")
  writeFileSync(versionPath, versionRb.replace(/VERSION = "[^"]+"/, `VERSION = "${version}"`))
}

step("npm run build")
step("bundle exec rake test")
step("bundle exec rubocop")

if (capture("git status --porcelain") !== "") {
  step(`git commit -am "Release ${tag}"`)
}
step(`git tag ${tag}`)

console.log(`\nTagged ${tag}. Publishing happens in CI once you push:\n\n  git push origin main ${tag}\n`)

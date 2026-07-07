import { defineConfig } from "@playwright/test"

const port = Number(process.env.PORT || 4173)

export default defineConfig({
  testDir: "test/browser",
  use: { baseURL: `http://localhost:${port}` },
  webServer: {
    command: "node test/browser/server.mjs",
    url: `http://localhost:${port}`,
    reuseExistingServer: !process.env.CI
  }
})

# Releasing

This repo publishes two packages from one source tree: the `lexxy-variables`
gem (rubygems.org) and the `lexxy-variables` npm package (npmjs.com). Their
versions always match. Publishing happens in GitHub Actions via trusted
publishing (OIDC) when a release tag is pushed. No registry credentials live
on your machine or in GitHub secrets.

## Cutting a release

1. Make sure `CHANGELOG.md` has a `## X.Y.Z` section for the new version
   describing what changed. Call out anything a host app must do when
   upgrading. The release script refuses to run without it.

2. On a clean `main` with the latest changes pulled, run:

       npm run release -- patch

   Pass `minor`, `major`, an explicit `X.Y.Z`, or `current` instead as
   appropriate. `current` releases the version already in the files without
   bumping. The script updates `lib/lexxy_variables/version.rb` and
   `package.json` in lockstep, syncs `vendor/` from `src/`, stamps today's
   date on the changelog section, runs the tests and RuboCop, then commits
   `Release vX.Y.Z` and creates the tag. Nothing is pushed or published yet.

3. Push the commit and the tag. This is the go button:

       git push origin main vX.Y.Z

4. Watch the Release workflow in the Actions tab. The `verify` job checks
   that the tag, both version files, and the vendored assets agree and runs
   the tests, then `publish-gem` and `publish-npm` push to the registries.

5. Confirm the new version and README rendering:
   - https://rubygems.org/gems/lexxy-variables
   - https://www.npmjs.com/package/lexxy-variables

If one publish job fails, fix the cause and re-run just that job from the
Actions UI. The other registry is unaffected. If `verify` fails, nothing was
published: fix the problem, delete the tag locally and remotely, and start
over.

## One-time trusted publisher setup

Do this once per registry before the first CI release. It authorizes this
repo's `release.yml` workflow to publish without any stored token.

- rubygems.org: on the lexxy-variables gem page, open Ownership, then
  Trusted publishers, and add a GitHub Actions publisher with repository
  `anquinn/lexxy-variables` and workflow filename `release.yml`.
- npmjs.com: in the lexxy-variables package settings, add a GitHub Actions
  trusted publisher with repository `anquinn/lexxy-variables` and workflow
  filename `release.yml`.

Required 2FA on both accounts is fully compatible with trusted publishing
and recommended alongside it. On npm, also set publishing access to
"Require two-factor authentication and disallow tokens" so classic tokens
cannot publish at all.

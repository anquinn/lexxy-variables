# Releasing

This repo publishes two packages from one source tree: the `lexxy-variables`
gem (rubygems.org) and the `lexxy-variables` npm package (npmjs.com). Their
versions must always match. Work through this list in order.

## 1. Preflight

- [ ] Working tree is clean and you are on `main` with the latest changes pulled.
- [ ] Decide the new version using semver. Breaking config or markup changes
      bump the major (minor while pre-1.0), new features bump the minor,
      fixes bump the patch.

## 2. Version bump

- [ ] Update `LexxyVariables::VERSION` in `lib/lexxy_variables/version.rb`.
- [ ] Update `"version"` in `package.json` to the same number.

## 3. Assets

- [ ] Run `npm run build` to copy `src/` to `vendor/`.
- [ ] Confirm the copies are in sync:

      diff src/lexxy/variable_extension.js vendor/javascript/lexxy_variables.js
      diff src/styles/lexxy_variables.css vendor/stylesheets/lexxy_variables.css

## 4. Changelog

- [ ] Add a section for the new version to `CHANGELOG.md` with the date and
      what changed. Call out anything a host app must do when upgrading.

## 5. Checks

- [ ] `bundle exec rake test`
- [ ] `bundle exec rubocop`
- [ ] `gem build lexxy-variables.gemspec` succeeds. Spot-check the file list
      with `gem spec lexxy-variables-X.Y.Z.gem files`.
- [ ] `npm publish --dry-run` shows the expected files (src, README, LICENSE).

## 6. Tag

- [ ] Commit the release: `git commit -am "Release vX.Y.Z"`
- [ ] Tag it: `git tag vX.Y.Z`
- [ ] Push both: `git push && git push --tags`

## 7. Publish

- [ ] `gem push lexxy-variables-X.Y.Z.gem`
- [ ] `npm publish`

## 8. Verify

- [ ] https://rubygems.org/gems/lexxy-variables shows the new version and the
      README renders correctly.
- [ ] https://www.npmjs.com/package/lexxy-variables shows the new version.
- [ ] In a scratch app, `bundle update lexxy-variables` and confirm the editor
      extension and a render still work.
- [ ] Delete the local `.gem` file.

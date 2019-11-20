# sem-ver-sh
## About semver.sh
semver.sh is a software release automation bash script which using [Semantic Versioning (SemVer)](https://semver.org/) software versioning schemes. It's analize git's commites titles after last pushed tag (if any exists) and manage new tag|release version. After successful release can push new version as a tag to remote origin with all commits messages as a release note(changelog) inside tag's body.
Can create separate changeleg file (default: CHANGELOG.md) if sem-ver.sh run with --changelog key.
Can update package version in package version file (package.json etc) if specified via '-f' key followed with 'VERSION_FILE' argument.
## Git commit title patterns
semver.sh using [commitizen](https://github.com/commitizen) style commit titles patterns for defining new SemVer. 
Any commit's titles should starts with the following pattern:
- **Major** Version commit title pattern:
  - *BREAKING CHANGE:*
- **Minor** Version commit title pattern:
  - *feat:*
- **Patch** Version commit title patterns: 
  - *fix:*
  - *docs:*
  - *style:*
  - *refactor:*
  - *perf:*
  - *test:*
  - *chore:*
Commits with other titles'll have no any affect in Semantic Versioning and just will be added in "Other" section of release note(changelog).
## Options
For script usage run:
```
sem-ver.sh --help
```

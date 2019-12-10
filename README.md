# sem-ver-sh
## About semver.sh
semver.sh is a software release automation bash script which using [Semantic Versioning (SemVer)](https://semver.org/) software versioning schemes. It's analize git's commites titles after last pushed tag (if any exists) and manage new tag|release version. After successful release can push new version as a tag to remote origin with all commits messages as a release note(changelog) inside tag's body.
Can create separate changeleg file (default: CHANGELOG.md) if sem-ver.sh run with --changelog key.
Can update package version in package version file (package.json etc) if specified via '-f' key followed with 'VERSION_FILE' argument.
## Git commit messages patterns
For defining new SemVer semver.sh is using [commitizen](https://github.com/commitizen) style commit titles patterns. 

Patterns are:
- **Major** Version commit pattern:
  - *BREAKING CHANGE*

Should be always capitalize. Major version pattern also could be put in commit body.

- **Minor** Version commit title pattern:
  - *feat:*
- **Patch** Version commit title patterns: 
  - *fix:* or *fix(some text|scope here):*
  - *docs:* or *docs(some text|scope here):*
  - *style:* or *style(some text|scope here):*
  - *refactor:* or *refactor(some text|scope here):*
  - *perf:* or *perf(some text|scope here):*
  - *test:* or *test(some text|scope here):*
  - *chore:* or *chore(some text|scope here):*

Pattern word for minor and patch version could starts with capitale letter or be fully capitalize. They should be put at the begining of the commit title.

Commits with other titles will have no any affect in Semantic Versioning and just will be added in "Other" section of release note(changelog).
## Options
For script usage run:
```
sem-ver.sh --help
```

# sem-ver-sh
## About semver.sh
semver.sh is a software release automation bash script which using [Semantic Versioning (SemVer)](https://semver.org/) software versioning schemes. 
It's analize [commitizen](https://github.com/commitizen) style git's commites messages and manage new tag|release version. 
Ad default behaviour semver.sh push new version as a tag to remote origin with all commit's messages as a release note(changelog) inside tags body, so it can be used in any CI/CD pipeline for versioning successful release.
Can create separate changelog file (default: CHANGELOG.md) if sem-ver.sh run with '--changelog' key.
Can update package version in package version file (package.json etc) if specified '-f' key followed with 'VERSION_FILE' package file name as an argument.
## Git commit messages patterns
For defining new SemVer semver.sh is using commit messages patterns. 

Patterns are:
- **Major** Version commit pattern:
  - *BREAKING CHANGE*

Should be always capitalize. Major version pattern could be put in commit message title or body.

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

Pattern for minor and patch version could starts with capitale letter or be fully capitalize. They can also include scope as descibed above.  Always should be put at the begining of the commit title.

Commits with other patterns wouldn't affect on Semantic Versioning and just will be added in "Other" section of release note(changelog, tag's body).
## Options
For script usage run:
```
sem-ver.sh --help
```

# sem-ver-sh
## About semver.sh
semver.sh is a software release automation bash script which using [Semantic Versioning (SemVer)](https://semver.org/) software versioning schemes. 
It's analize [commitizen](https://github.com/commitizen) style git's commites messages and manage new tag|release version. 
As default behaviour semver.sh push new version as a tag to remote origin with all commit's messages as a release note(changelog) inside tag's body, so it can be used at the end of any CI/CD pipeline for versioning successful release.
Can manage separate changelog file and update package version in package version file (package.json etc). See *Options* section.
## Git commit messages patterns
For defining new SemVer semver.sh is using commit messages patterns. 

***Patterns are:***
- **Major** Version commit pattern:
  - *BREAKING CHANGE*

> Should be always capitalize. Major version pattern always should be put in commit message title or in message body.

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

> Pattern for minor and patch version could starts with capitale letter or be fully capitalize. They can also include scope as described above.  Always should be put at the begining of the commit's title.

Commits with other patterns wouldn't affect on Semantic Versioning and just will be added in "Other" section of release note(changelog, tag's body).
## Usage
***Options:***
- **--dry-run**
  - run in dry run mode to analyze and get new SemVer, but don't do anything. Useful to use it at the begining CI/CD pipeline to determinate new release version
- **--changelog CHANGE_LOG_FILE**
  - add release notes in CHANGE_LOG_FILE if it's provided as an argument or to CHANGELOG.md (default)
- **-f VERSION_FILE**
  - update package version in VERSION_FILE
- **--help**
  - show semver.sh help

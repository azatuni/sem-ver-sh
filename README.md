# sem-ver-sh
## About semver.sh
semver.sh is a software release automation bash script which using [Semantic Versioning (SemVer)](https://semver.org/) software versioning schemes. 
It's analize [commitizen](https://github.com/commitizen) style git's commites messages and manage new tag|release version. 
As default behaviour semver.sh push new version as a tag to remote origin with all commit's messages as a release note(changelog) inside tag's body, so it can be used at the end of any CI/CD pipeline for versioning successful release.
Can manage separate changelog file and update package version in package version file, for example package.json etc. For detailed description see *Usage* section.
## Git commit messages patterns
For defining new SemVer semver.sh is using commit messages patterns. 
***Patterns are:***
- **Major** Version commit pattern:
  - *BREAKING CHANGE*
> Should be always capitalize. Major version pattern always should be put in commit message title or in message body.
- **Minor** Version commit title pattern:
  - *feat:* or *feat(some text|scope here):*
- **Patch** Version commit title patterns: 
  - *fix:* or *fix(some text|scope here):*
  - *docs:* or *docs(some text|scope here):*
  - *style:* or *style(some text|scope here):*
  - *refactor:* or *refactor(some text|scope here):*
  - *perf:* or *perf(some text|scope here):*
  - *test:* or *test(some text|scope here):*
  - *chore:* or *chore(some text|scope here):*
> Pattern for minor and patch version could starts with capitale letter or be fully capitalize. They can also include scope as described above.  Always should be put at the begining of the commit's title and have colon at it's end as shown above.
> Commits with other patterns wouldn't affect on Semantic Versioning and just will be added in "Other" section of release note(changelog, tag's body).
## Git commit patterns explanation
- BREAKING CHANGE - A commit that make backwards incompatible changes
- feat - A commit that make a new feature. If is backwards incompatible then should contain BREAKING CHANGE in commit's header or body
- fix - A bug fix
- docs - Documentation only changes
- style - Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)
- refactor - A code change that neither fixes a bug or adds a feature
- perf - A code change that improves performance
- test - Adding missing tests
- chore - Changes to the build process or auxiliary tools and libraries such as documentation generation
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

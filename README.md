# sem-ver-sh
sem-ver.sh is a software release automation bash script which using [Semantic Verioning (SemVer)](https://semver.org/) software versioning schemes. It's analize git's commites titles after last pushed tag and manage new tag|release version. After successful release can push new version as a tag to remote origin with all commits messages as a release note inside tag's body.
###### git commit title patterns
For using semver.sh all commit's should starts with the following patterns:
- Major Version commit title pattern:
  - **BREAKING CHANGE:**
- Minor Version commit title pattern:
  - **feat:**
- Patch Version commit title patterns: 
  - *fix:*
  - *docs:*
  - *style:*
  - *refactor:*
  - *perf:*
  - *test:*
  - *chore:*
###### semver.sh options
For script usage run:
```
sem-ver.sh --help
```

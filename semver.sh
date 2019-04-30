#!/bin/bash
MAJOR_VERSION_PATTERN="BREAKING CHANGE"
MINOR_VERSION_PATTERN="feat:"
PATCH_VERSION_PATTERN="fix: docs: style: refactor: perf: test: chore:"
CHANGELOG_FILE="CHANGELOG.MD"

function semversh_help () {
echo -e "
Usage: $0
\t-b branch_name\t
\t--dry-run\trun script in the dry run mode
"
}

function analyze_version () {
if [ "$LATEST_VERSION" == "0.0.0" ]
	then	case $1 in
			major)
				git log --pretty=%s\ %H | grep -qi "$MAJOR_VERSION_PATTERN" && increment_version major
			;;
			minor)
				git log --pretty=%s\ %H | grep -qi "^$MINOR_VERSION_PATTERN" && increment_version minor
			;;
			patch)
				for pattern in "$PATCH_VERSION_PATTERN"
				do
					git log --pretty=%s\ %H | grep -qi ^$pattern && increment_version patch && break
				done
			;;	
		esac
	else	COMMITS_COUNT_SINCE_LATEST_VERSION=`git log --pretty=%s\ %H | grep $LATEST_VERSION_COMMIT -B1000 | grep -v $LATEST_VERSION_COMMIT|wc -l`
		test $COMMITS_COUNT_SINCE_LATEST_VERSION == 0 && echo -e "Nothing is committed since latest version|release" && exit 3
		case $1 in 
			major)
				git log --pretty=%s\ %H | grep $LATEST_VERSION_COMMIT -B1000 | grep -v $LATEST_VERSION_COMMIT | grep -qi "$MAJOR_VERSION_PATTERN" && increment_version major
			;;	
			minor)
				git log --pretty=%s\ %H | grep $LATEST_VERSION_COMMIT -B1000 | grep -v $LATEST_VERSION_COMMIT | grep -qi ^$MINOR_VERSION_PATTERN && increment_version minor
			;;
			patch)
				for pattern in $PATCH_VERSION_PATTERN
				do
					git log --pretty=%s\ %H | grep $LATEST_VERSION_COMMIT -B1000 | grep -v $LATEST_VERSION_COMMIT | grep -qi ^$pattern && increment_version patch && break
				done
			;;
		esac
fi
}

function increment_version () {
unset NEW_VERSION
CURRENT_MAJOR_VERSION=`echo $LATEST_VERSION| awk -F. '{print $1}'`
CURRENT_MINOR_VERSION=`echo $LATEST_VERSION| awk -F. '{print $2}'`
CURRENT_PATCH_VERSION=`echo $LATEST_VERSION| awk -F. '{print $3}'`
case $1 in
	major)
		((CURRENT_MAJOR_VERSION++))
		NEW_VERSION="$CURRENT_MAJOR_VERSION.0.0"
	;;
	minor)
		((CURRENT_MINOR_VERSION++))
		NEW_VERSION="$CURRENT_MAJOR_VERSION.$CURRENT_MINOR_VERSION.0"
	;;
	patch)
		((CURRENT_PATCH_VERSION++))
		NEW_VERSION="$CURRENT_MAJOR_VERSION.$CURRENT_MINOR_VERSION.$CURRENT_PATCH_VERSION"
	;;
esac
echo -e "New version set to $NEW_VERSION"
}

function check_git_health () {
if ! git status > /dev/null
	then	echo -e "`pwd` is not git directory" && exit 2
elif ! git log --pretty=oneline > /dev/null
	then	echo "No old commits logs found" && exit 3
fi
}

function get_last_sem_ver () {
if git describe --tags --abbrev=0 &> /dev/null
	then	LATEST_GIT_TAG=`git describe --tags --abbrev=0`
		LATEST_VERSION=`echo $LATEST_GIT_TAG | sed s/v//`
		LATEST_VERSION_COMMIT=`git rev-list -n 1 $LATEST_GIT_TAG`
		echo -e "Last release tag is $LATEST_GIT_TAG with $LATEST_VERSION_COMMIT commit hash"
	else	echo -e "No old git tags was found"
		LATEST_VERSION=0.0.0
fi
}

function set_latest_sem_ver () {
analyze_version major && test ! -z $NEW_VERSION && return
analyze_version minor && test ! -z $NEW_VERSION && return
analyze_version patch && test ! -z $NEW_VERSION && return
if [ -z $NEW_VERSION ]
        then    echo -e "No new version was set. Possibly wrong pattern/patterns for commit titles" && exit 4
fi
}

function parse_commit () {
if [ "$DRY_RUN" == "true" ]
	then	echo -e "\n$1(s) is/are:"
		for commit_hash in `echo $@| sed "s/$1//"`
		do
        		git show --quiet --pretty=format:%n%s%nAuthor\:\ %an\ \(%ae\)%nDate\:\ %ai%n%b%nURL\:\ https://$GIT_REMOTE_URL/commit/%h%n%n $commit_hash
		done
	else	echo -e "\n$1(s) is/are:" >> $CHANGELOG_FILE
		for commit_hash in `echo $@| sed "s/$1//"`
		do
        		git show --quiet --pretty=format:%n%s%nAuthor\:\ %an\ \(%ae\)%nDate\:\ %ai%n%b%nURL\:\ https://$GIT_REMOTE_URL/commit/%h%n%n $commit_hash >> $CHANGELOG_FILE
		done
fi
}

function analyze_change_log () {
GIT_ROOT_DIR=`git rev-parse --show-toplevel`
GIT_REMOTE_URL=`git config --get remote.origin.url| sed 's/.*@//;s/\.git//'`
test `pwd` != "$GIT_ROOT_DIR" && cd "$GIT_ROOT_DIR"
if [ "$LATEST_VERSION" == "0.0.0" ]
	then	BREAKING_CHANGE_COMMIT_HASHES=`git log --pretty=%s\ %H | grep -i "BREAKING"| grep  -Eo '[a-fA-F0-9]{5,40}' `
		FEATURE_COMMIT_HASHES=`git log --pretty=%s\ %H | grep -i "^feat"| grep  -Eo '[a-fA-F0-9]{5,40}' `
		FIX_COMMIT_HASHES=`git log --pretty=%s\ %H | grep -i "^fix"| grep  -Eo '[a-fA-F0-9]{5,40}' `
		DOCS_COMMIT_HASHES=`git log --pretty=%s\ %H | grep -i "^docs"| grep  -Eo '[a-fA-F0-9]{5,40}' `
		STYLE_COMMIT_HASHES=`git log --pretty=%s\ %H | grep -i "^style"| grep  -Eo '[a-fA-F0-9]{5,40}' `
		REFACTOR_COMMIT_HASHES=`git log --pretty=%s\ %H | grep -i "^refactor"| grep  -Eo '[a-fA-F0-9]{5,40}' `
		PERF_COMMIT_HASHES=`git log --pretty=%s\ %H | grep -i "^perf"| grep  -Eo '[a-fA-F0-9]{5,40}' `
		TEST_COMMIT_HASHES=`git log --pretty=%s\ %H | grep -i "^test"| grep  -Eo '[a-fA-F0-9]{5,40}' `
		CHORE_COMMIT_HASHES=`git log --pretty=%s\ %H | grep -i "^chore"| grep  -Eo '[a-fA-F0-9]{5,40}' `
		OTHER_COMMIT_HASHES=`git log --pretty=%s\ %H | grep -iv 'BREAKING\|^feat\|^fix\|^docs\|^style\|^refactor\|^perf\|^test\|^chore'|grep  -Eo '[a-fA-F0-9]{5,40}' `
	else	BREAKING_CHANGE_COMMIT_HASHES=`git log --pretty=%s\ %H |grep $LATEST_VERSION_COMMIT -B1000 | grep -v $LATEST_VERSION_COMMIT | grep -i "BREAKING"| grep  -Eo '[a-fA-F0-9]{5,40}'`
		FEATURE_COMMIT_HASHES=`git log --pretty=%s\ %H | grep $LATEST_VERSION_COMMIT -B1000 | grep -v $LATEST_VERSION_COMMIT | grep -i "^feat"| grep  -Eo '[a-fA-F0-9]{5,40}' `
                FIX_COMMIT_HASHES=`git log --pretty=%s\ %H |grep $LATEST_VERSION_COMMIT -B1000 | grep -v $LATEST_VERSION_COMMIT | grep -i "^fix"| grep  -Eo '[a-fA-F0-9]{5,40}' `
                DOCS_COMMIT_HASHES=`git log --pretty=%s\ %H |grep $LATEST_VERSION_COMMIT -B1000 | grep -v $LATEST_VERSION_COMMIT | grep -i "^docs"| grep  -Eo '[a-fA-F0-9]{5,40}' `
                STYLE_COMMIT_HASHES=`git log --pretty=%s\ %H |grep $LATEST_VERSION_COMMIT -B1000 | grep -v $LATEST_VERSION_COMMIT | grep -i "^style"| grep  -Eo '[a-fA-F0-9]{5,40}' `
                REFACTOR_COMMIT_HASHES=`git log --pretty=%s\ %H |grep $LATEST_VERSION_COMMIT -B1000 | grep -v $LATEST_VERSION_COMMIT | grep -i "^refactor"| grep  -Eo '[a-fA-F0-9]{5,40}' `
                PERF_COMMIT_HASHES=`git log --pretty=%s\ %H |grep $LATEST_VERSION_COMMIT -B1000 | grep -v $LATEST_VERSION_COMMIT | grep -i "^perf"| grep  -Eo '[a-fA-F0-9]{5,40}' `
                TEST_COMMIT_HASHES=`git log --pretty=%s\ %H |grep $LATEST_VERSION_COMMIT -B1000 | grep -v $LATEST_VERSION_COMMIT | grep -i "^test"| grep  -Eo '[a-fA-F0-9]{5,40}' `
                CHORE_COMMIT_HASHES=`git log --pretty=%s\ %H |grep $LATEST_VERSION_COMMIT -B1000 | grep -v $LATEST_VERSION_COMMIT | grep -i "^chore"| grep  -Eo '[a-fA-F0-9]{5,40}' `
		OTHER_COMMIT_HASHES=`git log --pretty=%s\ %H |grep $LATEST_VERSION_COMMIT -B1000 | grep -v $LATEST_VERSION_COMMIT | grep -iv 'BREAKING\|^feat\|^fix\|^docs\|^style\|^refactor\|^perf\|^test\|^chore'|grep  -Eo '[a-fA-F0-9]{5,40}' `
fi

if [ ! -z "$BREAKING_CHANGE_COMMIT_HASHES" ]
	then	for commit_hash in $BREAKING_CHANGE_COMMIT_HASHES
		do	FEATURE_COMMIT_HASHES=`echo $FEATURE_COMMIT_HASHES | sed "s/$commit_hash//"`
			FIX_COMMIT_HASHES=`echo $FIX_COMMIT_HASHES | sed "s/$commit_hash//"`
			DOCS_COMMIT_HASHES=`echo $DOCS_COMMIT_HASHES | sed "s/$commit_hash//"`
			STYLE_COMMIT_HASHES=`echo $STYLE_COMMIT_HASHES | sed "s/$commit_hash//"`
			REFACTOR_COMMIT_HASHES=`echo $REFACTOR_COMMIT_HASHES | sed "s/$commit_hash//"`
			PERF_COMMIT_HASHES=`echo $PERF_COMMIT_HASHES | sed "s/$commit_hash//"`
			TEST_COMMIT_HASHES=`echo $TEST_COMMIT_HASHES | sed "s/$commit_hash//"`
			CHORE_COMMIT_HASHES=`echo $CHORE_COMMIT_HASHES | sed "s/$commit_hash//"`
			OTHER_COMMIT_HASHES=`echo $OTHER_COMMIT_HASHES| sed "s/$commit_hash//"`
		done
fi

if [ "$DRY_RUN" != "true" ]
	then	cat /dev/null > $CHANGELOG_FILE
		echo "Release v$NEW_VERSION" >> $CHANGELOG_FILE
fi
test `echo $BREAKING_CHANGE_COMMIT_HASHES | wc -w` != 0 && parse_commit "Breaking_change" "$BREAKING_CHANGE_COMMIT_HASHES"
test `echo $FEATURE_COMMIT_HASHES | wc -w` != 0 && parse_commit "Feature" "$FEATURE_COMMIT_HASHES"
test `echo $FIX_COMMIT_HASHES | wc -w` != 0 && parse_commit "Fix" "$FIX_COMMIT_HASHES"
test `echo $DOCS_COMMIT_HASHES | wc -w` != 0 && parse_commit "Doc" "$DOCS_COMMIT_HASHES"
test `echo $STYLE_COMMIT_HASHES | wc -w` != 0 && parse_commit "Style" "$STYLE_COMMIT_HASHES"
test `echo $REFACTOR_COMMIT_HASHES | wc -w` != 0 && parse_commit "Refactor" "$REFACTOR_COMMIT_HASHES"
test `echo $PERF_COMMIT_HASHES | wc -w` != 0 && parse_commit "Perf" "$PERF_COMMIT_HASHES"
test `echo $TEST_COMMIT_HASHES | wc -w` != 0 && parse_commit "Test" "$TEST_COMMIT_HASHES"
test `echo $CHORE_COMMIT_HASHES | wc -w` != 0 && parse_commit  "Chore" "$CHORE_COMMIT_HASHES"
test `echo $OTHER_COMMIT_HASHES | wc -w` != 0 && parse_commit "Other" "$CHORE_COMMIT_HASHES"

if [ "$DRY_RUN" != "true" ]
	then	echo -e "Chagelog file $CHANGELOG_FILE has been created/recreated with the following content"
		cat $CHANGELOG_FILE
fi
}

function push_change_log () {
git add $CHANGELOG_FILE && git commit -m "Release v$NEW_VERSION $CHANGELOG_FILE" && git push origin master
}

function push_tag () {
git tag -a v"$NEW_VERSION" -m "Release $NEW_VERSION"
git push origin v"$NEW_VERSION"
}

function skal_run () {
check_git_health
get_last_sem_ver
set_latest_sem_ver
analyze_change_log
}

function dry_run () {
DRY_RUN="true"
skal_run
}

function full_run () {
skal_run
push_change_log
push_tag
}

if [ $1 == "--help" ] || [ $1 == "-h" ]
	then semversh_help && exit 0
elif [ $# != 0 ]
	then	if echo $@ | grep -q "\-b"
			then	GIT_BRANCH=`echo $@| grep -o "\-b\ [a-zA-Z0-9]\{1,\}"| cut -d " " -f2`
			else	GIT_BRANCH="master"
		fi

		if echo $@ | grep -q "\-\-dry\-run"
			then	dry_run
			else	full_run
		fi
	else	GIT_BRANCH="master"
		full_run
fi

#!/bin/bash
#Version: 0.0.9
#Author: https://github.com/azatuni/sem-ver-sh


function set_variables () {
#Git commit title patterns
MAJOR_VERSION_PATTERN="BREAKING CHANGE"
MINOR_VERSION_PATTERN="feat:"
PATCH_VERSION_PATTERN="fix: docs: style: refactor: perf: test: chore:"
#Get version
SEMVERSH_VERSION=`head $0| grep Version| cut -d ' ' -f2`
#Echo colours
RED='\e[31m'
GREEN='\e[1;32m'
BLUE='\e[1;34m'
NORMAL=$(tput sgr0)
BOLD=$(tput bold)
INFO_STATUS="${YELLOW}${BOLD}[ INFO ]${NORMAL}"
FATAL_ERROR="${RED}${BOLD}[ FATAL_ERROR! ]${NORMAL}"
OK_STATUS="${GREEN}${BOLD}[ OK ]${NORMAL}"
FAIL_STATUS="${RED}${BOLD}[ FAILED ]${NORMAL}"
DONE_STATUS="${GREEN}${BOLD}[ DONE ]${NORMAL}"
}

function semversh_help () {
echo -e "${BLUE}                                       _     
                                      | |    
  ___  ___ _ __ _____   _____ _ __ ___| |__  
 / __|/ _ \ '_ \` _ \ \ / / _ \ '__/ __| '_ \ 
 \__ \  __/ | | | | \ V /  __/ |_ \__ \ | | |
 |___/\\___|_| |_| |_|\\_/ \\___|_(_)|___/_| |_|
\t\tVERSION: $SEMVERSH_VERSION${NORMAL}"
echo -e "Usage: $0
\t-h|--help\t\t\tshow this help and exit from script
\t[ -b BRANCH_NAME ]\t\tanalyze commit log from specific git branch. It is not recommendated to use this parameter. Default branch: 'master'
\t[ -f VERSION_FILE ]\t\tdefine file with package version in which new tag will be set as version in 'version' line
\t[ --changelog CHANGELOG_FILE ]\twrite changelog also in file. If CHANGELOG_FILE is not defined 'CHANGELOG.md' will be used
\t--dry-run\t\t\trun $0 in the dry run mode (no any updates pushed)
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
				for pattern in $PATCH_VERSION_PATTERN
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
echo -e "New version set to ${GREEN}$NEW_VERSION${NORMAL}"
}

function check_git_health () {
if ! git status > /dev/null
	then	echo -e "${RED}`pwd` is not git directory\t${FATAL_ERROR}" && exit 2
elif ! git log --pretty=oneline > /dev/null
	then	echo -e "${RED}No old commits logs found\t${FATAL_ERROR}" && exit 3
fi
}

function get_last_sem_ver () {
if git describe --tags --abbrev=0 &> /dev/null
	then	LATEST_GIT_TAG=`git describe --tags --abbrev=0`
		LATEST_VERSION=`echo $LATEST_GIT_TAG | sed s/v//`
		LATEST_VERSION_COMMIT=`git rev-list -n 1 $LATEST_GIT_TAG`
		echo -e "Last release tag is ${GREEN}$LATEST_GIT_TAG${NORMAL} with ${GREEN}$LATEST_VERSION_COMMIT${NORMAL} commit hash"
	else	echo -e "No old git tags was found"
		LATEST_VERSION=0.0.0
fi
}

function set_latest_sem_ver () {
analyze_version major && test ! -z $NEW_VERSION && return
analyze_version minor && test ! -z $NEW_VERSION && return
analyze_version patch && test ! -z $NEW_VERSION && return
if [ -z "$NEW_VERSION" ] 
        then    echo -e "${RED}No new version was set. Possibly wrong pattern/patterns for commit titles\t${FATAL_ERROR}" && exit 4
fi
}

function parse_commit () {
		echo -e "\n$1(s) is/are:"
		for commit_hash in `echo $@| sed "s/$1//"`
		do
        		git show --quiet --pretty=format:%n%s%nAuthor\:\ %an\ \(%ae\)%nDate\:\ %ai%n%b%nURL\:\ https://$GIT_REMOTE_WEB_URL/commit/%h%n%n $commit_hash
		done
}

function analyze_change_log () {
GIT_ROOT_DIR=`git rev-parse --show-toplevel`
GIT_REMOTE_WEB_URL=`git config --get remote.origin.url| sed 's/.*@//;s/\.git//;s/\:/\//'`
test `pwd` != "$GIT_ROOT_DIR" && cd "$GIT_ROOT_DIR"
if [ "$LATEST_VERSION" == "0.0.0" ]
	then	BREAKING_CHANGE_COMMIT_HASHES=`git log --pretty=%s\ %H | grep -i "BREAKING"| grep  -Eo '[a-fA-F0-9]{5,40}$' `
		FEATURE_COMMIT_HASHES=`git log --pretty=%s\ %H | grep -i "^feat"| grep  -Eo '[a-fA-F0-9]{5,40}$' `
		FIX_COMMIT_HASHES=`git log --pretty=%s\ %H | grep -i "^fix"| grep  -Eo '[a-fA-F0-9]{5,40}$' `
		DOCS_COMMIT_HASHES=`git log --pretty=%s\ %H | grep -i "^docs"| grep  -Eo '[a-fA-F0-9]{5,40}$' `
		STYLE_COMMIT_HASHES=`git log --pretty=%s\ %H | grep -i "^style"| grep  -Eo '[a-fA-F0-9]{5,40}$' `
		REFACTOR_COMMIT_HASHES=`git log --pretty=%s\ %H | grep -i "^refactor"| grep  -Eo '[a-fA-F0-9]{5,40}$' `
		PERF_COMMIT_HASHES=`git log --pretty=%s\ %H | grep -i "^perf"| grep  -Eo '[a-fA-F0-9]{5,40}$' `
		TEST_COMMIT_HASHES=`git log --pretty=%s\ %H | grep -i "^test"| grep  -Eo '[a-fA-F0-9]{5,40}$' `
		CHORE_COMMIT_HASHES=`git log --pretty=%s\ %H | grep -i "^chore"| grep  -Eo '[a-fA-F0-9]{5,40}$' `
		OTHER_COMMIT_HASHES=`git log --pretty=%s\ %H | grep -iv 'BREAKING\|^feat\|^fix\|^docs\|^style\|^refactor\|^perf\|^test\|^chore'|grep  -Eo '[a-fA-F0-9]{5,40}$' `
	else	BREAKING_CHANGE_COMMIT_HASHES=`git log --pretty=%s\ %H |grep $LATEST_VERSION_COMMIT -B1000 | grep -v $LATEST_VERSION_COMMIT | grep -i "BREAKING"| grep  -Eo '[a-fA-F0-9]{5,40}$'`
		FEATURE_COMMIT_HASHES=`git log --pretty=%s\ %H | grep $LATEST_VERSION_COMMIT -B1000 | grep -v $LATEST_VERSION_COMMIT | grep -i "^feat"| grep  -Eo '[a-fA-F0-9]{5,40}$' `
                FIX_COMMIT_HASHES=`git log --pretty=%s\ %H |grep $LATEST_VERSION_COMMIT -B1000 | grep -v $LATEST_VERSION_COMMIT | grep -i "^fix"| grep  -Eo '[a-fA-F0-9]{5,40}$' `
                DOCS_COMMIT_HASHES=`git log --pretty=%s\ %H |grep $LATEST_VERSION_COMMIT -B1000 | grep -v $LATEST_VERSION_COMMIT | grep -i "^docs"| grep  -Eo '[a-fA-F0-9]{5,40}$' `
                STYLE_COMMIT_HASHES=`git log --pretty=%s\ %H |grep $LATEST_VERSION_COMMIT -B1000 | grep -v $LATEST_VERSION_COMMIT | grep -i "^style"| grep  -Eo '[a-fA-F0-9]{5,40}$' `
                REFACTOR_COMMIT_HASHES=`git log --pretty=%s\ %H |grep $LATEST_VERSION_COMMIT -B1000 | grep -v $LATEST_VERSION_COMMIT | grep -i "^refactor"| grep  -Eo '[a-fA-F0-9]{5,40}$' `
                PERF_COMMIT_HASHES=`git log --pretty=%s\ %H |grep $LATEST_VERSION_COMMIT -B1000 | grep -v $LATEST_VERSION_COMMIT | grep -i "^perf"| grep  -Eo '[a-fA-F0-9]{5,40}$' `
                TEST_COMMIT_HASHES=`git log --pretty=%s\ %H |grep $LATEST_VERSION_COMMIT -B1000 | grep -v $LATEST_VERSION_COMMIT | grep -i "^test"| grep  -Eo '[a-fA-F0-9]{5,40}$' `
                CHORE_COMMIT_HASHES=`git log --pretty=%s\ %H |grep $LATEST_VERSION_COMMIT -B1000 | grep -v $LATEST_VERSION_COMMIT | grep -i "^chore"| grep  -Eo '[a-fA-F0-9]{5,40}$' `
		OTHER_COMMIT_HASHES=`git log --pretty=%s\ %H |grep $LATEST_VERSION_COMMIT -B1000 | grep -v $LATEST_VERSION_COMMIT | grep -iv 'BREAKING\|^feat\|^fix\|^docs\|^style\|^refactor\|^perf\|^test\|^chore'|grep  -Eo '[a-fA-F0-9]{5,40}$' `
fi
#Haskanal es inch a???
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

test `echo $BREAKING_CHANGE_COMMIT_HASHES | wc -w` != 0 && parse_commit "Breaking_change" "$BREAKING_CHANGE_COMMIT_HASHES"
test `echo $FEATURE_COMMIT_HASHES | wc -w` != 0 && parse_commit "Feature" "$FEATURE_COMMIT_HASHES"
test `echo $FIX_COMMIT_HASHES | wc -w` != 0 && parse_commit "Fix" "$FIX_COMMIT_HASHES"
test `echo $DOCS_COMMIT_HASHES | wc -w` != 0 && parse_commit "Doc" "$DOCS_COMMIT_HASHES"
test `echo $STYLE_COMMIT_HASHES | wc -w` != 0 && parse_commit "Style" "$STYLE_COMMIT_HASHES"
test `echo $REFACTOR_COMMIT_HASHES | wc -w` != 0 && parse_commit "Refactor" "$REFACTOR_COMMIT_HASHES"
test `echo $PERF_COMMIT_HASHES | wc -w` != 0 && parse_commit "Perf" "$PERF_COMMIT_HASHES"
test `echo $TEST_COMMIT_HASHES | wc -w` != 0 && parse_commit "Test" "$TEST_COMMIT_HASHES"
test `echo $CHORE_COMMIT_HASHES | wc -w` != 0 && parse_commit  "Chore" "$CHORE_COMMIT_HASHES"
test `echo $OTHER_COMMIT_HASHES | wc -w` != 0 && parse_commit "Other" "$OTHER_COMMIT_HASHES"


BREAKING_CHANGE_COMMIT_HASHES_COUNT=`echo $BREAKING_CHANGE_COMMIT_HASHES | wc -w`
FEATURE_COMMIT_HASHES_COUNT=`echo $FEATURE_COMMIT_HASHES | wc -w`
FIX_COMMIT_HASHES_COUNT=`echo $FIX_COMMIT_HASHES | wc -w`
DOCS_COMMIT_HASHES_COUNT=`echo $DOCS_COMMIT_HASHES | wc -w`
STYLE_COMMIT_HASHES_COUNT=`echo $STYLE_COMMIT_HASHES | wc -w`
REFACTOR_COMMIT_HASHES_COUNT=`echo $REFACTOR_COMMIT_HASHES | wc -w`
PERF_COMMIT_HASHES_COUNT=`echo $PERF_COMMIT_HASHES | wc -w`
TEST_COMMIT_HASHES_COUNT=`echo $TEST_COMMIT_HASHES | wc -w`
CHORE_COMMIT_HASHES_COUNT=`echo $CHORE_COMMIT_HASHES | wc -w`
OTHER_COMMIT_HASHES_COUNT=`echo $OTHER_COMMIT_HASHES | wc -w`
}

function push_tag () {
git tag -a v"$NEW_VERSION" -m "
Release $NEW_VERSION
`analyze_change_log`
"
git push origin v"$NEW_VERSION"
}

function generate_changelog_file () {
echo -e "\nRelease $NEW_VERSION" >> $CHANGELOG_FILE && analyze_change_log >> $CHANGELOG_FILE
if [ $? == 0 ]
	then	echo "Generated changelog in $CHANGELOG_FILE file\t${OK_STATUS}"
fi
}

function update_version_file () {
VERSION_LINE_NUMBER=`cat -n $VERSION_FILE | grep -m1 version| awk '{print $1}'`
sed -i "${VERSION_LINE_NUMBER}s/"$OLD_VERSION_FROM_VERSION_FILE"/"$NEW_VERSION"/" "$VERSION_FILE" 
if [ $? == 0 ]
        then    echo -e "Changed version from $OLD_VERSION_FROM_VERSION_FILE to $NEW_VERSION in $VERSION_FILE\t${OK_STATUS}"
        else    echo -e "${RED}Failed to change version from $OLD_VERSION_FROM_VERSION_FILE to $NEW_VERSION in $VERSION_FILE\t${FATAL_ERROR}" && exit 7
fi
}



function commit_and_push_new_version_file () {
git add "$VERSION_FILE" && git commit -m "$0: version set from $OLD_VERSION_FROM_VERSION_FILE to $NEW_VERSION in $VERSION_FILE" && git push origin $GIT_BRANCH
}

function git_add_file () {
git status | grep -q "$1" && git add "$1"
}

function try_git_commit_push () {
GIT_STAGE_FILES=`git diff --name-only --cached`
test ! -z "$GIT_STAGE_FILES" && git commit -m "$0 modified $GIT_STAGE_FILES" && git push origin "$GIT_BRANCH"
}

function main_run () {
if [ "$DRY_RUN_MODE" == "yes" ]
	then	check_git_health
		get_last_sem_ver
		set_latest_sem_ver
		analyze_change_log
elif [ "$DRY_RUN_MODE" == "no" ]
	then	check_git_health
		get_last_sem_ver
		set_latest_sem_ver
		analyze_change_log
#tester ira funkciai mej mtcnel vor mihat try_funkciai anun darna
		test ! -z "$CHANGELOG_FILE" && generate_changelog_file && git_add_file "$CHANGELOG_FILE"
		test ! -z "$VERSION_FILE" && update_version_file && git_add_file "$VERSION_FILE"
		try_git_commit_push
		push_tag
else	echo -e "Error!" && exit 1
fi
}

function check_version_file () {
test -z $VERSION_FILE && echo -e "${RED}No version file specified after -f option\t${FATAL_ERROR}" && exit 5
test ! -f $VERSION_FILE && echo -e "${RED}$VERSION_FILE file doesn't exists\t${FATAL_ERROR}" && exit 6
OLD_VERSION_FROM_VERSION_FILE=`grep version $VERSION_FILE | grep -Eo "[0-9]{1,}.[0-9]{1,}.[0-9]{1,}"`
test -z $OLD_VERSION_FROM_VERSION_FILE && echo -e "${RED}No 'version' string was found  or old version was set in $VERSION_FILE." && echo -e "If it is a first release just set version to 0.0.0\t\t${FATAL_ERROR}" && exit 6
}


function pasparam_parser () {
if [  $# != 0 ]
        then    
		test $1 == '--help' || test $1 == '-h' && semversh_help && exit 0	
		echo $@ | grep -q '\-b' && GIT_BRANCH=`echo $@| grep -o "\-b\ [a-zA-Z0-9]\{1,\}"| cut -d " " -f2`
		echo $@ | grep -q '\-\-dry\-run' && DRY_RUN_MODE="yes" 
		echo $@ | grep -q '\-f' && VERSION_FILE=`echo $@| grep -o '\-f\ [a-zA-Z0-9_-.]\{1,\}'| cut -d " " -f2` && check_version_file
		if echo $@ | grep -q '\-\-changelog'
			then	CHANGELOG_FILE=`echo $@ | grep -o '\-\-changelog\ [a-zA-Z0-9_-.]\{3,\}'| cut -d " " -f2`
				test -z $CHANGELOG_FILE && CHANGELOG_FILE="CHANGELOG.md"
		fi
fi
test -z "$GIT_BRANCH" && GIT_BRANCH="master"
test -z "$DRY_RUN_MODE" && DRY_RUN_MODE="no"
}

set_variables
pasparam_parser $@
main_run

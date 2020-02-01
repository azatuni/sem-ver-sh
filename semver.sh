#!/bin/bash
#Version: 0.1.1
#Author: https://github.com/azatuni/sem-ver-sh


function set_variables () {
#Git commit title patterns
MAJOR_VERSION_PATTERN="BREAKING CHANGE"
MINOR_VERSION_PATTERN='feat:\|feat(.*):'
PATCH_VERSION_PATTERN=('fix:\|fix(.*):' 'docs\|docs(.*):' 'style:\|style(.*):' 'refactor:\|refactor(.*):' 'perf:\|perf(.*):' 'test:\|test(.*):' 'chore:\|chore(.*):')
#Patterns for every change
BREAKING_CHANGE_PATTERN="$MAJOR_VERSION_PATTERN"
FEATURE_PATTERN="$MINOR_VERSION_PATTERN"
FIX_PATTERN=${PATCH_VERSION_PATTERN[0]}
DOCS_PATTERN=${PATCH_VERSION_PATTERN[1]}
STYLE_PATTERN=${PATCH_VERSION_PATTERN[2]}
REFACTOR_PATTERN=${PATCH_VERSION_PATTERN[3]}
PERF_PATTERN=${PATCH_VERSION_PATTERN[4]}
TEST_PATTERN=${PATCH_VERSION_PATTERN[5]}
CHORE_PATTERN=${PATCH_VERSION_PATTERN[6]}
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
\t--dry-run\t\t\trun $0 in the dry run mode (no any updates pushed|commited)
"
}

function analyze_commit_hash () {
git show $1 | grep -q "$BREAKING_CHANGE_PATTERN" && BREAKING_CHANGE_COMMIT_HASHES="$BREAKING_CHANGE_COMMIT_HASHES $1"
git show --pretty=%s\ %H $1| grep -iq ^"$FEATURE_PATTERN" && FEATURE_COMMIT_HASHES="$FEATURE_COMMIT_HASHES $1"
git show --pretty=%s\ %H $1| grep -iq ^"$FIX_PATTERN" && FIX_COMMIT_HASHES="$FIX_COMMIT_HASHES $1"
git show --pretty=%s\ %H $1| grep -iq ^"$DOCS_PATTERN" && DOCS_COMMIT_HASHES="$DOCS_COMMIT_HASHES $1"
git show --pretty=%s\ %H $1| grep -iq ^"$STYLE_PATTERN" && STYLE_COMMIT_HASHES="$STYLE_COMMIT_HASHES $1"
git show --pretty=%s\ %H $1| grep -iq ^"$REFACTOR_PATTERN" && REFACTOR_COMMIT_HASHES="$REFACTOR_COMMIT_HASHES $1"
git show --pretty=%s\ %H $1| grep -iq ^"$PERF_PATTERN" && PERF_COMMIT_HASHES="$PERF_COMMIT_HASHES $1"
git show --pretty=%s\ %H $1| grep -iq ^"$TEST_PATTERN" && TEST_COMMIT_HASHES="$TEST_COMMIT_HASHES $1"
git show --pretty=%s\ %H $1| grep -iq ^"$CHORE_PATTERN" && CHORE_COMMIT_HASHES="$CHORE_COMMIT_HASHES $1"
}

function get_commit_hashes () {
if [ "$LATEST_VERSION" == "0.0.0" ]
        then    ALL_COMMIT_HASHES=`git log --pretty=%H`
	else	ALL_COMMIT_HASHES=`git log --pretty=%H| grep $LATEST_VERSION_COMMIT -B1000 | grep -v $LATEST_VERSION_COMMIT`
		#INTERUPT IF THERE ARE NO COMMITS SINCE LAST RELEASE
		test -z "$ALL_COMMIT_HASHES" && echo -e "Nothing is committed since latest version|release" && exit 3
fi
#Analize commit hash
for hash in $ALL_COMMIT_HASHES
do
	analyze_commit_hash $hash
done
}

function analyze_version () {
case $1 in
	major)
		test ! -z "$BREAKING_CHANGE_COMMIT_HASHES" && increment_version major
		;;
	minor)
		test ! -z  "$FEATURE_COMMIT_HASHES"
		;;
	patch)
		for hash in "$FIX_PATTERN" "$DOCS_PATTERN" "$STYLE_PATTERN" "$REFACTOR_PATTERN" "$PERF_PATTERN" "$TEST_PATTERN" "$CHORE_PATTERN"
		do
			test ! -z $hash && increment_version patch && break
		done
		;;
esac
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
	then	echo -e "${RED}`pwd` is not git directory\t${FATAL_ERROR}" && exit 2
elif ! git log --pretty=oneline > /dev/null
	then	echo -e "${RED}No old commits logs found\t${FATAL_ERROR}" && exit 3
fi
}

function get_last_sem_ver () {
if git describe --tags --abbrev=0 --always &> /dev/null
	then	LATEST_GIT_TAG=`git describe --tags --abbrev=0 --always`
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

function analyze_commit_hashes () {
git show $1 | grep -q $MAJOR_VERSION_PATTERN && BREAKING_CHANGE_COMMIT_HASHES="$BREAKING_CHANGE_COMMIT_HASHES $1"
FEATURE_COMMIT_HASHES=`git log --pretty=%s\ %H | grep -i "^feat"| grep  -Eo '[a-fA-F0-9]{5,40}$' `
FIX_COMMIT_HASHES=`git log --pretty=%s\ %H | grep -i "^fix"| grep  -Eo '[a-fA-F0-9]{5,40}$' `
DOCS_COMMIT_HASHES=`git log --pretty=%s\ %H | grep -i "^docs"| grep  -Eo '[a-fA-F0-9]{5,40}$' `
STYLE_COMMIT_HASHES=`git log --pretty=%s\ %H | grep -i "^style"| grep  -Eo '[a-fA-F0-9]{5,40}$' `
REFACTOR_COMMIT_HASHES=`git log --pretty=%s\ %H | grep -i "^refactor"| grep  -Eo '[a-fA-F0-9]{5,40}$' `
PERF_COMMIT_HASHES=`git log --pretty=%s\ %H | grep -i "^perf"| grep  -Eo '[a-fA-F0-9]{5,40}$' `
TEST_COMMIT_HASHES=`git log --pretty=%s\ %H | grep -i "^test"| grep  -Eo '[a-fA-F0-9]{5,40}$' `
CHORE_COMMIT_HASHES=`git log --pretty=%s\ %H | grep -i "^chore"| grep  -Eo '[a-fA-F0-9]{5,40}$' `
}


function analyze_change_log () {
GIT_ROOT_DIR=`git rev-parse --show-toplevel`
GIT_REMOTE_WEB_URL=`git config --get remote.origin.url| sed 's/.*@//;s/\.git//;s/\:/\//'`
test `pwd` != "$GIT_ROOT_DIR" && cd "$GIT_ROOT_DIR"
#Filter other commit hashes
OTHER_COMMIT_HASHES="$ALL_COMMIT_HASHES"
for hash in $BREAKING_CHANGE_COMMIT_HASHES $FEATURE_COMMIT_HASHES $FIX_COMMIT_HASHES $DOCS_COMMIT_HASHES $STYLE_COMMIT_HASHES $REFACTOR_COMMIT_HASHES $PERF_COMMIT_HASHES $TEST_COMMIT_HASHES $CHORE_COMMIT_HASHES
do
	test ! -z "$OTHER_COMMIT_HASHES" && OTHER_COMMIT_HASHES=`echo "$OTHER_COMMIT_HASHES" | sed "s/$hash//"`
done
#Clean BREAKING_CHANEG commit hashes from other commit hashes
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
#Pass existing hashes to parse_commit function
test ! -z "$BREAKING_CHANGE_COMMIT_HASHES" && parse_commit "Breaking_change" "$BREAKING_CHANGE_COMMIT_HASHES"
test ! -z "$FEATURE_COMMIT_HASHES" && parse_commit "Feature" "$FEATURE_COMMIT_HASHES"
test ! -z "$FIX_COMMIT_HASHES" && parse_commit "Fix" "$FIX_COMMIT_HASHES"
test ! -z "$DOCS_COMMIT_HASHES" && parse_commit "Doc" "$DOCS_COMMIT_HASHES"
test ! -z "$STYLE_COMMIT_HASHES" && parse_commit "Style" "$STYLE_COMMIT_HASHES"
test ! -z "$REFACTOR_COMMIT_HASHES" && parse_commit "Refactor" "$REFACTOR_COMMIT_HASHES"
test ! -z "$PERF_COMMIT_HASHES" && parse_commit "Perf" "$PERF_COMMIT_HASHES"
test ! -z "$TEST_COMMIT_HASHES" && parse_commit  "Chore" "$CHORE_COMMIT_HASHES"
test ! -z "$CHORE_COMMIT_HASHES" && parse_commit  "Chore" "$CHORE_COMMIT_HASHES"
test ! -z "$OTHER_COMMIT_HASHES" && parse_commit "Other" "$OTHER_COMMIT_HASHES"
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
		get_commit_hashes
		set_latest_sem_ver
		analyze_change_log
elif [ "$DRY_RUN_MODE" == "no" ]
	then	check_git_health
		get_last_sem_ver
		get_commit_hashes
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
test -z "$VERSION_FILE" && echo -e "${RED}No version file specified after -f option\t${FATAL_ERROR}" && exit 5
test ! -f "$VERSION_FILE" && echo -e "${RED}$VERSION_FILE file doesn't exists\t${FATAL_ERROR}" && exit 6
OLD_VERSION_FROM_VERSION_FILE=`grep version $VERSION_FILE | grep -Eo "[0-9]{1,}.[0-9]{1,}.[0-9]{1,}"`
test -z "$OLD_VERSION_FROM_VERSION_FILE" && echo -e "${RED}No 'version' string was found  or old version was set in $VERSION_FILE." && echo -e "If it is a first release just set version to 0.0.0\t\t${FATAL_ERROR}" && exit 6
}


function pasparam_parser () {
if [  $# != 0 ]
        then    
		test $1 == '--help' || test $1 == '-h' && semversh_help && exit 0	
		echo $@ | grep -q '\-b' && GIT_BRANCH=`echo $@| grep -o "\-b\ [a-zA-Z0-9]\{1,\}"| cut -d " " -f2`
		echo $@ | grep -q '\-\-dry\-run' && DRY_RUN_MODE="yes" 
		echo $@ | grep -q '\-f' && VERSION_FILE=`echo $@| grep -o '\-f\ [a-zA-Z0-9_.-]\{1,\}'| cut -d " " -f2` && check_version_file
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

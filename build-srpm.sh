#!/bin/sh

set -e

MYDIR="$(dirname $(readlink -m $0))"

GIT_DIR=$(cd $MYDIR && readlink -m $(git rev-parse --git-dir))

export GIT_DIR

# Functions copied from the specfile
latestcommitstamp() {
	git rev-list -n1 --format=format:%ct HEAD | tail -n1
}

releasestr() {
	echo $(date -u +%Y%m%dT%H%M%SZ --date=@$(latestcommitstamp)).git$(git rev-list --abbrev-commit -n1 HEAD)
}

if [ -d "rpm" ]; then
	echo "A folder called rpm already exists, please delete it before running this script."
	exit 1
fi

mkdir -p rpm/SOURCES rpm/SPECS

RPMDIR="$(readlink -m rpm)"

RELEASESTR=$(releasestr)
FOLDER_NAME="s3proxy-${RELEASESTR}"

git archive --format=tar --prefix="${FOLDER_NAME}/" HEAD | bzip2 -c > "$RPMDIR/SOURCES/${FOLDER_NAME}.tar.bz2"

SPECFILE="$RPMDIR/SPECS/s3proxy.spec"

echo -e "# AUTO GENERATED BY build-srpm.sh, DO NOT EDIT BY HAND\n" > $SPECFILE

# We need to expand those macros now, since in the chroot build environment we
# won't have access to git etc.
sed \
	-e "/^%define latestcommitstamp /d" \
	-e "s/^%define releasestr .\\+/%define releasestr $RELEASESTR/" \
	s3proxy.spec >> $SPECFILE

rpmbuild -bs --define "%_topdir $RPMDIR" $SPECFILE

echo "SRPM built in $RPMDIR/SRPMS/"
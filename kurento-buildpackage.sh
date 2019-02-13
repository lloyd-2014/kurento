#!/usr/bin/env bash

#/ Kurento packaging script for Debian/Ubuntu.
#/
#/ This shell script is used to build all Kurento Media Server
#/ modules, and generate Debian/Ubuntu package files from them.
#/
#/ The script must be called from within a Git repository.
#/
#/
#/ Arguments
#/ ---------
#/
#/ --install-kurento <KurentoVersion>
#/
#/   Install Kurento dependencies that are required to build the package.
#/
#/   <KurentoVersion> indicates which Kurento version must be used to download
#/   packages from. E.g.: "6.8.0". If "dev" or "nightly" is given, the
#/   Kurento nightly packages will be used instead.
#/
#/   Typically, you will provide an actual version number when also using
#/   the '--release' flag, and just use "nightly" otherwise. In this mode,
#/   `apt-get` will download and install all required packages from the
#/   Kurento repository for Ubuntu.
#/
#/   If none of the '--install-*' arguments are provided, all required
#/   dependencies are expected to be already installed in the system.
#/
#/   This argument is useful for end users, or external developers which may
#/   want to build a specific component of Kurento without having to build
#/   all the dependencies.
#/
#/   Optional. Default: Disabled.
#/   See also: --install-files
#/
#/ --install-files [FilesDir]
#/
#/   Install Kurento dependencies that are required to build the package.
#/
#/   [FilesDir] is optional, it sets a directory where all '.deb' files
#/   are located with required dependencies.
#/
#/   This argument is useful during incremental builds where dependencies have
#/   been built previously but are still not available to download with
#/   `apt-get`, maybe as a product of previous jobs in a CI pipeline.
#/
#/   If none of the '--install-*' arguments are provided, all required
#/   dependencies are expected to be already installed in the system.
#/
#/   Optional. Default: Disabled.
#/   See also: --install-kurento
#/
#/ --srcdir <SrcDir>
#/
#/   Specifies in which sub-directory the script should work. If not specified,
#/   all operations will be done in the current directory where the script has
#/   been called.
#/
#/   The <SrcDir> MUST contain a 'debian/' directory with all Debian files,
#/   which are used to define how to build the project and generate packages.
#/
#/   This argument is useful for Git projects that contain submodules. Running
#/   directly from a submodule directory might cause some problems if the
#/   command `git-buildpackage` is not able to identify the submodule as a
#/   proper Git repository.
#/
#/   Optional. Default: Current working directory.
#/
#/ --dstdir <DstDir>
#/
#/   Specifies where the resulting Debian package files ('*.deb') should be
#/   placed after the build finishes.
#/
#/   Optional. Default: Current working directory.
#/
#/ --allow-dirty
#/
#/   Allows building packages from a working directory where there are
#/   unstaged and/or uncommited changes.
#/   If this option is not given, the working directory must be clean.
#/
#/   NOTE: This tells `dpkg-buildpackage` to skip calling `dpkg-source` and
#/   build a Binary-only package. It makes easier creating a test package, but
#/   in the long run the objective is to create oficially valid packages which
#/   comply with Debian/Ubuntu's policies, so this option should not be used
#/   for final published packages.
#/
#/   Optional. Default: Disabled.
#/
#/ --release
#/
#/   Build packages intended for Release.
#/   If this option is not given, packages are built as nightly snapshots.
#/
#/   Optional. Default: Disabled.
#/
#/ --timestamp <Timestamp>
#/
#/   Apply the provided timestamp instead of using the date and time this
#/   script is being run.
#/
#/   <Timestamp> must be a decimal number. Ideally, it represents some date
#/   and time when the build was done. It can also be any arbitrary number.
#/
#/   Optional. Default: Current date and time, as given by the command
#/   `date --utc +%Y%m%d%H%M%S`.
#/
#/
#/ Dependency tree
#/ ---------------
#/
#/ * git-buildpackage
#/   - Python 3 (pip, setuptools, wheel)
#/   - debuild (package 'devscripts')
#/     - dpkg-buildpackage (package 'dpkg-dev')
#/     - lintian
#/   - git
#/     - openssh-client (for Git SSH access)
#/ * lsb-release
#/ * mk-build-deps (package 'devscripts')
#/   - equivs
#/ * nproc (package 'coreutils')
#/ * realpath (package 'coreutils')
#/
#/
#/ Dependency install
#/ ------------------
#/
#/ apt-get update && apt-get install --yes \
#/   python3 python3-pip python3-setuptools python3-wheel \
#/   devscripts \
#/   dpkg-dev \
#/   lintian \
#/   git \
#/   openssh-client \
#/   lsb-release \
#/   equivs \
#/   coreutils
#/ pip3 install --upgrade gbp



# Shell setup
# -----------

BASEPATH="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"  # Absolute canonical path
# shellcheck source=bash.conf.sh
source "$BASEPATH/bash.conf.sh" || exit 1



# Check permissions
# -----------------

[[ "$(id -u)" -eq 0 ]] || {
    log "ERROR: Please run as root user (or with 'sudo')"
    exit 1
}



# Parse call arguments
# --------------------

CFG_INSTALL_KURENTO="false"
CFG_INSTALL_KURENTO_VERSION="0.0.0"
CFG_INSTALL_FILES="false"
CFG_INSTALL_FILES_DIR="$PWD"
CFG_SRCDIR="$PWD"
CFG_DSTDIR="$PWD"
CFG_ALLOW_DIRTY="false"
CFG_RELEASE="false"
CFG_TIMESTAMP="$(date --utc +%Y%m%d%H%M%S)"

while [[ $# -gt 0 ]]; do
    case "${1-}" in
        --install-kurento)
            if [[ -n "${2-}" ]]; then
                CFG_INSTALL_KURENTO="true"
                CFG_INSTALL_KURENTO_VERSION="$2"
                shift
            else
                log "ERROR: --install-kurento expects <KurentoVersion>"
                log "Run with '--help' to read usage details"
                exit 1
            fi
            ;;
        --install-files)
            CFG_INSTALL_FILES="true"
            if [[ -n "${2-}" ]]; then
                CFG_INSTALL_FILES_DIR="$(realpath $2)"
                shift
            fi
            ;;
        --srcdir)
            if [[ -n "${2-}" ]]; then
                CFG_SRCDIR="$(realpath $2)"
                shift
            else
                log "ERROR: --srcdir expects <SrcDir>"
                log "Run with '--help' to read usage details"
                exit 1
            fi
            ;;
        --dstdir)
            if [[ -n "${2-}" ]]; then
                CFG_DSTDIR="$(realpath $2)"
                shift
            else
                log "ERROR: --dstdir expects <DstDir>"
                log "Run with '--help' to read usage details"
                exit 1
            fi
            ;;
        --allow-dirty)
            CFG_ALLOW_DIRTY="true"
            ;;
        --release)
            CFG_RELEASE="true"
            ;;
        --timestamp)
            if [[ -n "${2-}" ]]; then
                CFG_TIMESTAMP="$2"
                shift
            else
                log "ERROR: --timestamp expects <Timestamp>"
                log "Run with '--help' to read usage details"
                exit 1
            fi
            ;;
        *)
            log "ERROR: Unknown argument '${1-}'"
            log "Run with '--help' to read usage details"
            exit 1
            ;;
    esac
    shift
done

log "CFG_INSTALL_KURENTO=${CFG_INSTALL_KURENTO}"
log "CFG_INSTALL_KURENTO_VERSION=${CFG_INSTALL_KURENTO_VERSION}"
log "CFG_INSTALL_FILES=${CFG_INSTALL_FILES}"
log "CFG_INSTALL_FILES_DIR=${CFG_INSTALL_FILES_DIR}"
log "CFG_SRCDIR=${CFG_SRCDIR}"
log "CFG_DSTDIR=${CFG_DSTDIR}"
log "CFG_ALLOW_DIRTY=${CFG_ALLOW_DIRTY}"
log "CFG_RELEASE=${CFG_RELEASE}"
log "CFG_TIMESTAMP=${CFG_TIMESTAMP}"



# Setup control variables
# -----------------------

APT_UPDATE_NEEDED="true"



# Apt configuration
# -----------------

# If requested, add the repository
if [[ "$CFG_INSTALL_KURENTO" == "true" ]]; then
    log "Requested installation of Kurento packages"

    log "Add the Kurento Apt repository key"
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 5AFA7A83

    if [[ "$CFG_INSTALL_KURENTO_VERSION" == "nightly" ]]; then
        # Set correct repo name for nightly versions
        REPO="dev"
    else
        REPO="$CFG_INSTALL_KURENTO_VERSION"
    fi

    log "Add the Kurento Apt repository line"
    APT_FILE="$(mktemp /etc/apt/sources.list.d/kurento-XXXXX.list)"
    DISTRO="$(lsb_release --codename --short)"
    echo "deb [arch=amd64] http://ubuntu.openvidu.io/$REPO $DISTRO kms6" \
        >"$APT_FILE"

    # Adding a new repo requires updating the Apt cache
    if [[ "$APT_UPDATE_NEEDED" == "true" ]]; then
        apt-get update
        APT_UPDATE_NEEDED="false"
    fi
fi

# If requested, install local packages
# This is done _after_ installing from the Kurento repository, because
# installation of local files might be useful to overwrite some default
# version of packages.
if [[ "$CFG_INSTALL_FILES" == "true" ]]; then
    log "Requested installation of package files"

    if ls -f "${CFG_INSTALL_FILES_DIR}"/*.*deb >/dev/null 2>&1; then
        dpkg --install "${CFG_INSTALL_FILES_DIR}"/*.*deb || {
            log "Try to install remaining dependencies"
            if [[ "$APT_UPDATE_NEEDED" == "true" ]]; then
                apt-get update
                APT_UPDATE_NEEDED="false"
            fi
            apt-get install --yes --fix-broken --no-remove
        }
    else
        log "No '.deb' package files are present!"
    fi
fi



# Enter Work Directory
# --------------------

# All next commands expect to be run from the path that contains
# the actual project and its 'debian/' directory

pushd "$CFG_SRCDIR" || {
    log "ERROR: Cannot change to source dir: '$CFG_SRCDIR'"
    exit 1
}



# Install dependencies
# --------------------

log "Install build dependencies"

if [[ "$APT_UPDATE_NEEDED" == "true" ]]; then
    apt-get update
    APT_UPDATE_NEEDED="false"
fi

mk-build-deps --install --remove \
    --tool='apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends --yes' \
    ./debian/control

# HACK
# By default, 'dh_strip' in Debian will generate '-dbgsym' packages automatically
# from each binary package defined in the control file. This eliminates the need
# to define '-dbg' files explicitly and manually:
#     https://wiki.debian.org/AutomaticDebugPackages
#
# This mechanism also works in Ubuntu 16.04 (Xenial) and earlier, but only if
# the package 'pkg-create-dbgsym' is already installed at build time, so we need
# to install it before building the package.
#
# Ubuntu 18.04 (Bionic) doesn't need this any more, because it already comes
# with Debhelper v10, which has this as the default behavior.
#
# REVIEW 2019-02-05 - Disable automatic generation of debug packages
# For now, we'll keep on defining '-dbg' packages in 'debian/control'.
# DISTRO_YEAR="$(lsb_release -s -r | cut -d. -f1)"
# if [[ $DISTRO_YEAR -lt 18 ]]; then
#     apt-get install --yes pkg-create-dbgsym
# fi



# Run git-buildpackage
# --------------------

# To build Release packages, the 'debian/changelog' file must be updated and
# committed by a developer, as part of the release process. Then the build
# script uses it to assign a version number to the resulting packages.
# For example, a developer would run:
#     gbp dch --git-author --release debian/
#     git add debian/changelog
#     git commit -m "Update debian/changelog with new release version"
#
# For nightly (pre-release) builds, the 'debian/changelog' file is
# auto-generated by the build script with a snapshot version number. This
# snapshot information is never committed.
#
# git-buildpackage arguments:
#
# --git-ignore-new ignores the uncommitted 'debian/changelog'.
#
# --ignore-branch allows building from a tag or a commit.
#   If not set, GBP would enforce that the current branch is the
#   "debian-branch" specified in 'gbp.conf' (or 'master', by default).
#
# --git-upstream-tree=SLOPPY generates the source tarball from the current
#   state of the working directory.
#   If not set, GBP would search for upstream source files in
#   the "upstream-branch" specified in 'gbp.conf' (or 'upstream' by default).
#
# --git-author uses the Git user details for the entry in 'debian/changelog'.
#
# Other arguments are passed to `debuild` and `dpkg-buildpackage`.



# Update debian/changelog
# -----------------------

if [[ "$CFG_RELEASE" == "true" ]]; then
    log "Update debian/changelog for a RELEASE version build"
    gbp dch \
        --ignore-branch \
        --git-author \
        --spawn-editor=never \
        --release \
        ./debian/
else
    log "Update debian/changelog for a NIGHTLY snapshot build"
    gbp dch \
        --ignore-branch \
        --git-author \
        --spawn-editor=never \
        --snapshot --snapshot-number="$CFG_TIMESTAMP" \
        ./debian/
fi



# Build Debian packages
# ---------------------

# Arguments passed to 'dpkg-buildpackage'
ARGS="-uc -us -j$(nproc)"

if [[ "$PARAM_INSTALL_FILES" == "true" ]]; then
    # Tell `dpkg-source` to generate its source tarball by
    # ignoring *.deb and *.ddeb files inside $PARAM_INSTALL_FILES_DIR
    ARGS="$ARGS --source-option=--extend-diff-ignore=.*\.d?deb$"
fi

if [[ "$PARAM_ALLOW_DIRTY" == "true" ]]; then
    # Tell `dpkg-buildpackage` to build a Binary-only package,
    # skipping `dpkg-source` source tarball altogether.
    ARGS="$ARGS -b"
fi

if [[ "$CFG_RELEASE" == "true" ]]; then
    log "Run git-buildpackage to generate a RELEASE version build"
    gbp buildpackage \
        --git-ignore-new \
        --git-ignore-branch \
        --git-upstream-tree=SLOPPY \
        $ARGS
else
    log "Run git-buildpackage to generate a NIGHTLY snapshot build"
    gbp buildpackage \
        --git-ignore-new \
        --git-ignore-branch \
        --git-upstream-tree=SLOPPY \
        $ARGS
fi





# Move packages
# -------------

# `dh_builddeb` puts by default the generated '.deb' files in '../'
# so move them to the target destination directory.
# Use 'find | xargs' here because we need to skip moving if the source
# and destination paths are the same.
find "$(realpath ..)" -maxdepth 1 -type f -name '*.*deb' \
    -not -path "$CFG_DSTDIR/*" -print0 \
| xargs -0 --no-run-if-empty mv --target-directory="$CFG_DSTDIR"



# Exit Work Directory
# -------------------

popd || true  # "$CFG_SRCDIR"



log "Done!"

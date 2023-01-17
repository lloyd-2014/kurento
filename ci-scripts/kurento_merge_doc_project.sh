#!/usr/bin/env bash

#/ Generate and commit source files for Read The Docs.
#/
#/ Arguments
#/ ---------
#/
#/ --release
#/
#/   Build documentation sources intended for Release.
#/   If this option is not given, sources are built as nightly snapshots.
#/
#/   Optional. Default: Disabled.



# Shell setup
# -----------

BASEPATH="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"  # Absolute canonical path
# shellcheck source=bash.conf.sh
source "$BASEPATH/bash.conf.sh" || exit 1

log "==================== BEGIN ===================="

# Trace all commands
set -o xtrace



# Parse call arguments
# --------------------

CFG_RELEASE="false"

while [[ $# -gt 0 ]]; do
    case "${1-}" in
        --release)
            CFG_RELEASE="true"
            ;;
        *)
            log "WARNING: Unknown argument '${1-}'"
            log "Run with '--help' to read usage details"
            ;;
    esac
    shift
done

log "CFG_RELEASE=${CFG_RELEASE}"



# Generate documentation sources
# ------------------------------

kurento_clone_repo.sh "$KURENTO_PROJECT"

{
    pushd "$KURENTO_PROJECT"

    [[ -x configure.sh ]] && ./configure.sh

    if [[ -z "${MAVEN_SETTINGS:+x}" ]]; then
        cp Makefile Makefile.ci
    else
        sed -e "s@mvn@mvn --settings ${MAVEN_SETTINGS}@g" Makefile > Makefile.ci
    fi

    make --file=Makefile.ci ci-readthedocs
    rm Makefile.ci

    if [[ "$CFG_RELEASE" = "true" ]]; then
        log "Command: kurento_check_version (tagging enabled)"
        kurento_check_version.sh "true"
    else
        log "Command: kurento_check_version (tagging disabled)"
        kurento_check_version.sh "false"
    fi

    popd  # $KURENTO_PROJECT
}



# Commit generated sources
# ------------------------

RTD_PROJECT="${KURENTO_PROJECT}-readthedocs"

kurento_clone_repo.sh "$RTD_PROJECT"

rsync -av --delete \
    --exclude-from="${KURENTO_PROJECT:?}/.gitignore" \
    --exclude='.git*' \
    "${KURENTO_PROJECT:?}/" "${RTD_PROJECT:?}/"

log "Commit and push changes to repo: $RTD_PROJECT"
GIT_COMMIT="$(git rev-parse --short HEAD)"

{
    pushd "$RTD_PROJECT"

    git status
    git diff-index --quiet HEAD || {
      # `--all` to include possibly deleted files.
      git add --all .
      git commit -m "Code autogenerated from Kurento/${KURENTO_PROJECT}@${GIT_COMMIT}"

      # Use the repo default branch.
      GIT_DEFAULT="$(kurento_git_default_branch.sh)"

      git push origin "$GIT_DEFAULT"
    }

    if [[ "$CFG_RELEASE" = "true" ]]; then
        log "Command: kurento_check_version (tagging enabled)"
        kurento_check_version.sh "true"
    else
        log "Command: kurento_check_version (tagging disabled)"
        kurento_check_version.sh "false"
    fi

    popd  # $RTD_PROJECT
}



log "==================== END ===================="
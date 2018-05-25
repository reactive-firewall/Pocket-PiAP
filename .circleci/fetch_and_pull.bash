#! /bin/bash

EXIT_CODE=0 ;
git checkout --force "${CIRCLE_BRANCH:-${CIRCLE_SHA1:-stable}}" 2>/dev/null || true ;
git fetch "${CIRCLE_BRANCH:-${CIRCLE_SHA1:-stable}}" || git fetch --all || EXIT_CODE=1 ; 
git pull || git pull --all || EXIT_CODE=1 ;
(git submodule init || true ) && git submodule update --remote --checkout && git submodule foreach git fetch --all || EXIT_CODE=1 ;

if [[ ( "${EXIT_CODE:-0}" -gt 0 ) ]] ; then
echo "ERROR"
echo "GIT ENV"
git config --list
echo "FETCH and PULL - FAILED"
else
echo "FETCH and PULL - DONE"
fi

exit "${EXIT_CODE:-0}";
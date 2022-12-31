#!/bin/bash
lastGitTag=$(git describe --tags $(git rev-list --tags --max-count=1) 2>/dev/null) 
currentReleaseTag=${lastGitTag:-"0.0.0"}
nextReleaseTag=
labels=

if [ -z "$lastGitTag" ]; then
    unreleasePRs=$(git log HEAD --merges --oneline | sed "s/^.*pull request #//g;s/ from.*//g")
else
    unreleasePRs=$(git log $lastGitTag..HEAD --merges --oneline | sed "s/^.*pull request #//g;s/ from.*//g")
fi

for id in $unreleasePRs
do
    labels+=" $(gh pr view $id --json labels -q .labels[].name)"
done

[ -z "$labels" ] && { echo "There is no label found."; exit 1; }

if [[ $labels == *"breaking-change"* ]]; then
    nextReleaseTag=$(echo $currentReleaseTag | awk -F. '{ver = sprintf("%s.%s.%s", $1+1, 0, 0); print ver }')
elif [[ $labels == *"feature"* ]]; then
    nextReleaseTag=$(echo $currentReleaseTag | awk -F. '{ver = sprintf("%s.%s.%s", $1, $2+1, 0); print ver }')
elif [[ $labels == *"bugfix"* ]]; then
    nextReleaseTag=$(echo $currentReleaseTag | awk -F. '{ver = sprintf("%s.%s.%s", $1, $2, $3+1); print ver }')
fi

[ -z "$nextReleaseTag" ] && { echo "Unable to generate the next release tag."; exit 1; }
echo $nextReleaseTag

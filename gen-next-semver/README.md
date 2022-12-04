### Generate the next semantic version based on Pull Request labels

#### Supported PR labels

* bugfix
* feature
* breaking-change

#### Usage

##### Local

```sh
cd YOUR_GIT_REPO_DIR
curl -s https://raw.githubusercontent.com/khanh-ph/github-actions-scripts/master/gen-next-semver/gen-next-semver.sh | bash
```

##### GitHub Actions

Below is just an example of how to use this script with GitHub Actions:

```yaml
#.github/workflows/draft-a-release.yml
name: Draft a new release

on: 
    workflow_dispatch:

jobs:
    draft-a-new-release:
        runs-on: ubuntu-latest
        steps:
        - name: Checkout
            uses: actions/checkout@v3
            with:
            fetch-depth: 0

        - name: Generate release tag
            env: 
            GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
            run: |
            VERSION=$(curl -s https://raw.githubusercontent.com/khanh-ph/github-actions-scripts/master/gen-next-semver/gen-next-semver.sh | bash)
            echo VERSION=$VERSION >> $GITHUB_ENV
            echo BRANCH=release/$VERSION >> $GITHUB_ENV

        - name: Create release branch
            run: |
            git checkout -b ${{ env.BRANCH }}
        
        - name: Push release branch
            run: git push origin ${{ env.BRANCH }}

        - name: Create a pull request
            uses: thomaseizinger/create-pull-request@1.0.0
            env:
            GITHUB_TOKEN: ${{ secrets.PAT }}
            with:
            head: ${{ env.BRANCH }}
            base: master
            title: Release version ${{ env.VERSION }}
```

```yaml
#.github/workflows/publish-a-release.yml
name: Publish a new release

on:
    pull_request:
        branches:
            - master
        types:
            - closed

jobs:
    publish-a-release:
        runs-on: ubuntu-latest
        if: github.event.pull_request.merged == true &&
            (startsWith(github.event.pull_request.head.ref, 'release/') || startsWith(github.event.pull_request.head.ref, 'hotfix/'))

        steps:
        - name: Extract version from release branch
            if: startsWith(github.event.pull_request.head.ref, 'release/')
            run: |
            BRANCH_NAME="${{ github.event.pull_request.head.ref }}"
            VERSION=${BRANCH_NAME#release/}
            echo "RELEASE_VERSION=$VERSION" >> $GITHUB_ENV

        - name: Extract version from hotfix branch
            if: startsWith(github.event.pull_request.head.ref, 'hotfix/')
            run: |
            BRANCH_NAME="${{ github.event.pull_request.head.ref }}"
            VERSION=${BRANCH_NAME#hotfix/}
            echo "RELEASE_VERSION=$VERSION" >> $GITHUB_ENV

        - name: Create Release
            uses: thomaseizinger/create-release@1.0.0
            env:
                GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
            with:
                target_commitish: ${{ github.event.pull_request.merge_commit_sha }}
                tag_name: ${{ env.RELEASE_VERSION }}
                name: ${{ env.RELEASE_VERSION }}
                draft: false
                prerelease: false
```
#!/bin/sh

set -e

source $(dirname $0)/helpers.sh

it_can_put_to_url() {
  local repo1=$(init_repo)

  local src=$(mktemp -d $TMPDIR/put-src.XXXXXX)
  local repo2=$src/repo
  git clone $repo1 $repo2

  local ref=$(make_commit $repo2)

  # create a tag to push
  git -C $repo2 tag some-tag

  # cannot push to repo while it's checked out to a branch
  git -C $repo1 checkout refs/heads/master

  put_uri $repo1 $src repo | jq -e "
    .version == {ref: $(echo $ref | jq -R .)}
  "

  # switch back to master
  git -C $repo1 checkout master

  test -e $repo1/some-file
  test "$(git -C $repo1 rev-parse HEAD)" = $ref
  test "$(git -C $repo1 rev-parse some-tag)" = $ref
}

it_can_put_to_url_with_tag() {
  local repo1=$(init_repo)

  local src=$(mktemp -d $TMPDIR/put-src.XXXXXX)
  local repo2=$src/repo
  git clone $repo1 $repo2

  local ref=$(make_commit $repo2)

  echo some-tag-name > $src/some-tag-file

  # cannot push to repo while it's checked out to a branch
  git -C $repo1 checkout refs/heads/master

  put_uri_with_tag $repo1 $src some-tag-file repo | jq -e "
    .version == {ref: $(echo $ref | jq -R .)}
  "

  # switch back to master
  git -C $repo1 checkout master

  test -e $repo1/some-file
  test "$(git -C $repo1 rev-parse HEAD)" = $ref
  test "$(git -C $repo1 rev-parse some-tag-name)" = $ref
}

it_can_put_to_url_with_tag_and_prefix() {
  local repo1=$(init_repo)

  local src=$(mktemp -d $TMPDIR/put-src.XXXXXX)
  local repo2=$src/repo
  git clone $repo1 $repo2

  local ref=$(make_commit $repo2)

  echo 1.0 > $src/some-tag-file

  # cannot push to repo while it's checked out to a branch
  git -C $repo1 checkout refs/heads/master

  put_uri_with_tag_and_prefix $repo1 $src some-tag-file v repo | jq -e "
    .version == {ref: $(echo $ref | jq -R .)}
  "

  # switch back to master
  git -C $repo1 checkout master

  test -e $repo1/some-file
  test "$(git -C $repo1 rev-parse HEAD)" = $ref
  test "$(git -C $repo1 rev-parse v1.0)" = $ref
}

it_can_put_to_url_with_rebase() {
  local repo1=$(init_repo)

  local src=$(mktemp -d $TMPDIR/put-src.XXXXXX)
  local repo2=$src/repo
  git clone $repo1 $repo2

  # make a commit that will require rebasing
  local baseref=$(make_commit_to_file $repo1 some-other-file)

  local ref=$(make_commit $repo2)

  # cannot push to repo while it's checked out to a branch
  git -C $repo1 checkout refs/heads/master

  local response=$(mktemp $TMPDIR/rebased-response.XXXXXX)

  put_uri_with_rebase $repo1 $src repo > $response

  local rebased_ref=$(git -C $repo2 rev-parse HEAD)

  jq -e "
    .version == {ref: $(echo $rebased_ref | jq -R .)}
  " < $response

  # switch back to master
  git -C $repo1 checkout master

  test -e $repo1/some-file
  test "$(git -C $repo1 rev-parse HEAD)" = $rebased_ref
}

it_can_put_to_url_with_rebase_with_tag() {
  local repo1=$(init_repo)

  local src=$(mktemp -d $TMPDIR/put-src.XXXXXX)
  local repo2=$src/repo
  git clone $repo1 $repo2

  # make a commit that will require rebasing
  local baseref=$(make_commit_to_file $repo1 some-other-file)

  local ref=$(make_commit $repo2)

  echo some-tag-name > $src/some-tag-file

  # cannot push to repo while it's checked out to a branch
  git -C $repo1 checkout refs/heads/master

  local response=$(mktemp $TMPDIR/rebased-response.XXXXXX)

  put_uri_with_rebase_with_tag $repo1 $src some-tag-file repo > $response

  local rebased_ref=$(git -C $repo2 rev-parse HEAD)

  jq -e "
    .version == {ref: $(echo $rebased_ref | jq -R .)}
  " < $response

  # switch back to master
  git -C $repo1 checkout master

  test -e $repo1/some-file
  test "$(git -C $repo1 rev-parse HEAD)" = $rebased_ref
  test "$(git -C $repo1 rev-parse some-tag-name)" = $rebased_ref
}

it_can_put_to_url_with_rebase_with_tag_and_prefix() {
  local repo1=$(init_repo)

  local src=$(mktemp -d $TMPDIR/put-src.XXXXXX)
  local repo2=$src/repo
  git clone $repo1 $repo2

  # make a commit that will require rebasing
  local baseref=$(make_commit_to_file $repo1 some-other-file)

  local ref=$(make_commit $repo2)

  echo 1.0 > $src/some-tag-file

  # cannot push to repo while it's checked out to a branch
  git -C $repo1 checkout refs/heads/master

  local response=$(mktemp $TMPDIR/rebased-response.XXXXXX)

  put_uri_with_rebase_with_tag_and_prefix $repo1 $src some-tag-file v repo > $response

  local rebased_ref=$(git -C $repo2 rev-parse HEAD)

  jq -e "
    .version == {ref: $(echo $rebased_ref | jq -R .)}
  " < $response

  # switch back to master
  git -C $repo1 checkout master

  test -e $repo1/some-file
  test "$(git -C $repo1 rev-parse HEAD)" = $rebased_ref
  test "$(git -C $repo1 rev-parse v1.0)" = $rebased_ref
}

it_can_put_with_git_ignore_ssl_default() {
  local repo1=$(init_repo)

  local src=$(mktemp -d $TMPDIR/put-src.XXXXXX)
  local repo2=$src/repo
  git clone $repo1 $repo2
  unset_http_ssl_verify

  put_uri_ignore_git_ssl_default $repo1 $src repo

  [ -z "$(git config --global --get http.sslVerify)" ]
}

it_can_put_with_git_ignore_ssl_true() {
  local repo1=$(init_repo)

  local src=$(mktemp -d $TMPDIR/put-src.XXXXXX)
  local repo2=$src/repo
  git clone $repo1 $repo2
  unset_http_ssl_verify

  put_uri_ignore_git_ssl_true $repo1 $src repo
  
  [[ $(git config --global --get http.sslVerify) == "false" ]]
}

run it_can_put_to_url
run it_can_put_to_url_with_tag
run it_can_put_to_url_with_tag_and_prefix
run it_can_put_to_url_with_rebase
run it_can_put_to_url_with_rebase_with_tag
run it_can_put_to_url_with_rebase_with_tag_and_prefix
run it_can_put_with_git_ignore_ssl_default
run it_can_put_with_git_ignore_ssl_true

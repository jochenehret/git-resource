#!/bin/sh

set -e

source $(dirname $0)/helpers.sh

it_can_get_from_url() {
  local repo=$(init_repo)
  local ref=$(make_commit $repo)
  local dest=$TMPDIR/destination

  get_uri $repo $dest | jq -e "
    .version == {ref: $(echo $ref | jq -R .)}
  "

  test -e $dest/some-file
  test "$(git -C $dest rev-parse HEAD)" = $ref
}

it_can_get_from_url_at_ref() {
  local repo=$(init_repo)
  local ref1=$(make_commit $repo)
  local ref2=$(make_commit $repo)

  local dest=$TMPDIR/destination

  get_uri_at_ref $repo $ref1 $dest | jq -e "
    .version == {ref: $(echo $ref1 | jq -R .)}
  "

  test -e $dest/some-file
  test "$(git -C $dest rev-parse HEAD)" = $ref1

  rm -rf $dest

  get_uri_at_ref $repo $ref2 $dest | jq -e "
    .version == {ref: $(echo $ref2 | jq -R .)}
  "

  test -e $dest/some-file
  test "$(git -C $dest rev-parse HEAD)" = $ref2
}

it_can_get_from_url_at_branch() {
  local repo=$(init_repo)
  local ref1=$(make_commit_to_branch $repo branch-a)
  local ref2=$(make_commit_to_branch $repo branch-b)

  local dest=$TMPDIR/destination

  get_uri_at_branch $repo "branch-a" $dest | jq -e "
    .version == {ref: $(echo $ref1 | jq -R .)}
  "

  test -e $dest/some-file
  test "$(git -C $dest rev-parse HEAD)" = $ref1

  rm -rf $dest

  get_uri_at_branch $repo "branch-b" $dest | jq -e "
    .version == {ref: $(echo $ref2 | jq -R .)}
  "

  test -e $dest/some-file
  test "$(git -C $dest rev-parse HEAD)" = $ref2
}

it_can_get_with_git_ignore_ssl_default() {
  local repo=$(init_repo)
  local dest=$TMPDIR/destination
  unset_http_ssl_verify

  get_uri_ignore_git_ssl_default $repo $dest

  [ -z "$(git config --global --get http.sslVerify)" ]
}

it_can_get_with_git_ignore_ssl_true() {
  local repo=$(init_repo)
  local dest=$TMPDIR/destination
  unset_http_ssl_verify

  get_uri_ignore_git_ssl_true $repo $dest

  [[ $(git config --global --get http.sslVerify) == "false" ]]
}

run it_can_get_from_url
run it_can_get_from_url_at_ref
run it_can_get_from_url_at_branch
run it_can_get_with_git_ignore_ssl_default
run it_can_get_with_git_ignore_ssl_true

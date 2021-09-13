#!/bin/bash

set -x

pushd $HOME/zhubx007.github.io

# add article
git add *

# add commit msg
git commit -m "My commit: `date "+%Y-%m-%d %H:%m:%S"`"

# hexo clean
hexo clean

# hexo generate
hexo g

# hexo deploy
hexo d

# git push
git fetch -a && git rebase origin/master && git push -u origin master

popd

set +x

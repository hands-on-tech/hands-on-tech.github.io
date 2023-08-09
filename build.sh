#!/bin/bash
BLOG_PATH="/Users/david.campos/Projects/webpage/blog"

JEKYLL_ENV=production jekyll build --baseurl '/blog' --destination "$BLOG_PATH"

rm -rf "$BLOG_PATH"/about
rm -rf $BLOG_PATH/social
rm $BLOG_PATH/build.sh
rm $BLOG_PATH/dependencies.sh
rm $BLOG_PATH/LICENSE.md
rm $BLOG_PATH/README.md
rm $BLOG_PATH/run.sh
rm $BLOG_PATH/social_schedule
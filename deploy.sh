#!/bin/bash

echo -e "\033[0;32mDeploying updates to Gitee...\033[0m"

# Build the project.
hugo --baseUrl='https://pismery.gitee.io/blog/'
# if using a theme, replace with `hugo -t <YOURTHEME>`

# Add changes to git.
git add .

# Commit changes.
msg="rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi
git commit -m "$msg"

# Push source and build repos.
git push gitee master

#!/bin/bash

echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"
# Build the project.
hugo --baseUrl='https://pismery.github.io/'
# if using a theme, replace with `hugo -t <YOURTHEME>`

# Add changes to git.
git add .

# Commit changes.
msg="rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi
git commit -m "$msg"

# Push source and build repos.
git push github master

# Go To Public folder
#cd public
# Add changes to git.
#git add .

# Commit changes.
#msg="rebuilding site `date`"
#if [ $# -eq 1 ]
  #then msg="$1"
#fi
#git commit -m "$msg"

# Push source and build repos.
#git push origin master

# Come Back up to the Project Root
#cd ..

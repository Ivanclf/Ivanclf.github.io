git checkout hexo-source
git add .
git commit -m "update source"
git push

git checkout main
cp -r public/* ./
git add .
git commit -m "update site"
git push

git checkout hexo-source
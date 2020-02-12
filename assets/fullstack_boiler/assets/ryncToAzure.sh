# rsync build to remote
rsync -avz --delete build/* $USER@$SERVER

# run this a few times to remove unneeded double spaces from build
# decreases bundle sizes
find build/ -type f -name "*.js" -exec sed -i 's/  / /g' {} \;
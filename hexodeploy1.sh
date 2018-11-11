#!/bin/sh
# must be md-source

deployAll() {
	# deploy to remote master branch
	cd d:
	cd 13hexo
	hexo clean
	hexo g -d
	# push to remote md-source branch
	
	#cp -R public/ .deploy_git/
	#cd .deploy_git/
	git add .
	git commit -m "source code"
	git push origin md-source
	#cd -
	#git add .
	#git commit -m "source code"
	#git push origin code
}
 
deployAll
 
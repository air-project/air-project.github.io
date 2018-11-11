#!/bin/sh
# hexodeploy (without creating issue)
# hexodeploy ~/Documents/../xxx.md (creating comment issue for md)


# 1. input article file path
# 2. create a new issue, including article title and link
# 3. deploy hexo

# Fetch title/date/permalink from .md file

articlePath=$1
title=''
date=''
permalink=''
commentIssueId='20'

ACCESS_TOKEN='27266172f87e4892d0fee4040f41c34501869963'

deployAll() {
	# deploy
	cd d:
	cd 13hexo
	hexo generate
	cp -R public/ .deploy_git/
	cd .deploy_git/
	git add .
	git commit -m "update"
	git push
	#cd -
	#git add .
	#git commit -m "source code"
	#git push origin code
}

readFromMdFile() {
	argument_count=0
	while IFS='' read -r line || [[ -n "$line" ]]; do
		#echo $line
	    if [[ $line == title:*  ]]; then 
	        title=$(echo $line|cut -d" " -f2)
	        argument_count=$(($argument_count+1))
	    elif [[ $line == date:* ]]; then
	    	date=$(echo $line|cut -d" " -f2)
	    	argument_count=$(($argument_count+1))
	    elif [[ $line == permalink:* ]]; then
	    	permalink=$(echo $line|cut -d" " -f2)
	    	argument_count=$(($argument_count+1))
	    elif [[ $line == commentIssueId:* ]]; then
	    	commentIssueId=$(echo $line|cut -d" " -f2)
	    	argument_count=$(($argument_count+1))
	    fi
	    if [[ $argument_count == 4 ]]; then
	    	break
	    fi  
	done < "$articlePath"

	date=`echo $date | tr '-' '/'`
	
	
}

readFromMdFile

echo $commentIssueId

	sed -i -e "s/commentIssueId.*/commentIssueId: $createdIssueId/" $articlePath
	readFromMdFile
	if [[ 'commentIssueId:'$commentIssueId == commentIssueId:* ]]; then
			echo "写入commentIssueId失败，请手动写入后直接deploy：" $createdIssueId
			exit 1
	fi
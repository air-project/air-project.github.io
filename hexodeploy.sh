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
commentIssueId=''

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
 
createIssue() {
	echo 'Creating Issue....'
	 
	# generate article data
	body='文章地址：https://air-project.github.io/'$date'/'$title
	data='{"title":"《'$title'》评论","body":"'$body'"}'
	echo data: $data

	# create a issue with title + link
	apiResult=$(curl --silent -H "Content-Type: application/json" -u air-project:$ACCESS_TOKEN -X POST -d $data https://api.github.com/repos/air-project/air-project.github.io/issues)
	
	echo apiResult: $apiResult
	commentId=$(echo $apiResult| jq -r '.number')
	echo commentId: $commentId
	
	if [[ $commentId == null ]]; then
		echo "---------\nError: 创建Issue失败\n---------"
		echo $apiResult
		exit 1
	else 
		return $commentId	
	fi
}
if [ "$#" == 1 ]; then
	# create issue for input articlePath
	echo "---------\n为指定文章创建Issue后再deploy\n---------"
	readFromMdFile
	echo title: $title
	echo date: $date
	echo permalink: $permalink
	echo commentIssueId: $commentIssueId
	if [[ $commentIssueId == commentIssueId:* ]]; then
		echo "---------\n无相关Issue，开始创建Issue\n----------"
		createIssue
		createdIssueId=$?
		echo "新创建的IssueId:" $createdIssueId
		echo "---------\n准备添加IssueId到文章中\n---------"
		sed -i -e "s/commentIssueId.*/commentIssueId: $createdIssueId/" $articlePath
		readFromMdFile
		if [[ $commentIssueId == commentIssueId:* ]]; then
			echo "写入commentIssueId失败，请手动写入后直接deploy：" $createdIssueId
			exit 1
		fi
		echo commentIssueId: $commentIssueId
		echo "---------\nIssueId添加成功，开始deploy\n---------"
		#deployAll
	else 
		echo "---------\n已存在Issue，直接Deploy\n---------"
		#deployAll
	fi
elif [[ "$#" == 0 ]]; then
	# no input -> deploy
	echo "---------\n直接deploy\n---------"
	#deployAll
else
	echo "参数错误"
	exit 1	
fi

#!/usr/bin/env bash

set -e
# set -x

git config --global user.email ${GIT_EMAIL}
git config --global user.name ${GIT_NAME}
git clone https://${GIT_ACCESS_TOKEN}@${GIT_LAB}/${GIT_NAME}/${GIT_REPO}.git

# 并发运行的最佳实践

# 并发数,并发数过大可能造成系统崩溃
Qp=5
# 存放进程的队列
Qarr=()
# 运行进程数
run=0
# 将进程的添加到队列里的函数
function push() {
	Qarr=(${Qarr[@]} $1)
	run=${#Qarr[@]}
}
# 检测队列里的进程是否运行完毕
function check() {
	oldQ=(${Qarr[@]})
	Qarr=()
	for p in "${oldQ[@]}";do
		if [[ -d "/proc/$p" ]];then
			Qarr=(${Qarr[@]} $p)	
		fi
	done
	run=${#Qarr[@]}
}

# prepare shared node_modules
for doc_dirname in `cat .docs`; do
    if [ -f "${GIT_REPO}/${doc_dirname}/package.json" ]; then
        echo "goto ${GIT_REPO}/$doc_dirname" && cd ${GIT_REPO}/$doc_dirname
        yarn 
        cd -
    fi
done

# main
for doc_dirname in `cat .docs`; do
    if [ -f "${GIT_REPO}/${doc_dirname}/deploy.sh" ]; then
        echo "goto ${GIT_REPO}/$doc_dirname" && cd ${GIT_REPO}/$doc_dirname
        chmod +x deploy.sh && ./deploy.sh &
        push $!
        cd -
    fi
	while [[ $run -gt $Qp ]];do
		check
		sleep 0.1
	done
done
wait

echo -e "time-consuming: $SECONDS   seconds"    #显示脚本执行耗时

set +e
# set +x

exit 0

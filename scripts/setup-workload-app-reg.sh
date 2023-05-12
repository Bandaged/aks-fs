appName=$1
appName=${appName:="test-mk-cluster"}
az ad app create --display-name $appName
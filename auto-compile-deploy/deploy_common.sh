port=$1
svn_path=$2
#域名
web_domain=$3
web_target_name=$4
web_config_test_dir=$5


deploy_workspace=/opt/deploy_workspace/
JAVA_HOME=/export/servers/j2sdk/
export_dir=/export/servers/
export_tomcat=/export/servers/tomcat6.0.33

run_flag_dir="/tmp/"$port
if [ ! -d "$run_flag_dir" ]; then
    mkdir -p "$run_flag_dir"
fi

#判断是否正在部署，如果是则退出
if [ -f "$run_flag_dir/.run" ]; then
    echo "程序部署中，请勿重复部署!"
    exit 1
fi


trap "rm -r $run_flag_dir/.run; exit 1" 2





tomcat_name=$port"_"$web_domain".tomcat"
tomcat_dir=$export_dir""$tomcat_name
if [ ! -d "$tomcat_dir" ]; then
        cp -r $export_tomcat $tomcat_dir
fi

echo "==================部署参数信息================="
echo "部署根目录:" $deploy_workspace
echo "jdk版本信息:" $JAVA_HOME
java -version
echo "部署Tomcat路径:" $tomcat_dir
echo "部署端口:" $port 
echo "部署项目svn路径:" $svn_path
echo "项目域名:" $web_domain
echo "部署war包名称" $web_target_name
#if [ $web_config_test_dir ]

#fi
echo "==============================================="


echo -e "修改tomcat端口..............................................................\n"        
var_shutdown_port="shutdown_port"
var_start_port="start_port"
shutdown_port=`expr $port + 10000` 
replace_start_port_str="s/$var_start_port/$port/g"
replace_shutdown_port_str="s/$var_shutdown_port/$shutdown_port/g"
echo $replace_start_port_str
echo $replace_shutdown_port_str
sed "$replace_start_port_str" $tomcat_dir"/conf/server.xml.deploy" > $tomcat_dir"/conf/server.xml.deploy1"
sed "$replace_shutdown_port_str" $tomcat_dir"/conf/server.xml.deploy1" > $tomcat_dir"/conf/server.xml"
echo -e "修改Tomcat端口成功.........................................................\n"


    
echo "##############################################################"
echo "开始svn下载代码。。。" 
echo "##############################################################"
    
cd $deploy_workspace 
if [ ! -d $web_domain ]; then
    svn co $svn_path $web_domain
else
    cd $web_domain
    svn up
fi


echo "##############################################################"
echo "开始编译代码。。。"
echo "##############################################################"
cd $deploy_workspace
cd $web_domain
cp -rf $web_target_name"/src/main"$web_config_test_dir"*" $web_target_name"/src/main/resources/"
mvn clean package  -DskipTests -U



if [ $? != 0 ]; then
        echo "##############################################################"
        echo -e 'mvn打包出错了，直接退出部署程序。。。';
        echo "##############################################################"
        exit 1
fi





echo "##############################################################"
echo "开始停止tomcat。。。"
echo "##############################################################"
sh  $tomcat_dir/bin/shutdown.sh
sleep 3
ps -ef  | grep $tomcat_name | grep -v grep |  awk  '{print $2}' | xargs kill -9




echo "##############################################################"
echo -e "开始部署程序。。。"
echo "##############################################################"
rm -fr $tomcat_dir/webapps/ROOT
cd $deploy_workspace
cd $web_domain
unzip -q  $web_target_name"/target/"$web_target_name"".war -d  $tomcat_dir"/webapps/ROOT"



echo "##############################################################"
echo -e "开始启动tomcat。。。"
echo "##############################################################"
export CATALINA_OPTS="-Xms512M -Xmx1024M -server -XX:PermSize=256M"
sh $tomcat_dir/bin/startup.sh

#删除.run文件，部署完毕
rm -r $run_flag_dir/.run;

echo "##############################################################"
echo -e "开始打印日志。。。"
echo "##############################################################"

tail -f  $tomcat_dir"/logs/catalina.out"



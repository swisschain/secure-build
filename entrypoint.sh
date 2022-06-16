#!/bin/bash

#Preparing

ibmcloud login --apikey $API_KEY --no-region
ibmcloud target -g Default
export IBMCLOUD_HOME=/usr/local/bin/
ibmcloud plugin install container-registry
ibmcloud plugin install hpvs
ibmcloud cr region-set eu-central
ibmcloud cr namespace-add $CR_NAME
mkdir ~/.ssh
cat << EOF > ~/.ssh/temp
$GIT_PRIVATE
EOF
cat ~/.ssh/temp | base64 -d > ~/.ssh/id_rsa
chmod 400 ~/.ssh/id_rsa
rm ~/.ssh/temp
git clone --single-branch --branch DO-1757-add-certificates https://x-access-token:$GIT_USER_API_TOKEN@github.com/swisschain/custody-certificates.git /tmp/git
ls -la /tmp/git
ls -la /tmp/git/$SERVICE_NAME
cd /tmp/git/$SERVICE_NAME
pip3 install -r requirements.txt
apt install pinentry-tty


#Build secure image

export GPG_TTY=$(tty)
build_out=$(./build.py instance-env --env sbs-config.json)
echo build_out=$build_out
env_certs=$(echo $build_out | awk -F"secure_build.asc " '{print $3}')
echo env_certs=$env_certs
cat <<EOF > temp
ibmcloud hpvs instance-create $BUILD_SERVER free fra05 --rd-path "secure_build.asc" -i 1.3.0.4 $env_certs
EOF
echo cat temp
cat temp
sh temp
echo "---------------------------------------------------------------------"
echo "                  Waiting build server     "
echo "---------------------------------------------------------------------"
echo ""
echo ""
sleep 600
build_ip=`ibmcloud hpvs instance $BUILD_SERVER 2>&1|grep "Public IP address"|awk '{print $4}'`
sed -i "s/x.x.x.x/$build_ip/g" sbs-config.json
sed -i "s/hostname/$HOSTNAME/g" sbs-config.json
echo "$build_ip   $HOSTNAME" >> /etc/hosts
./build.py init --env sbs-config.json
./build.py update --env sbs-config.json
./build.py build --env sbs-config.json
echo "---------------------------------------------------------------------"
echo "              Waiting for the build to complete     "
echo "---------------------------------------------------------------------"
echo ""
echo ""
sleep 500
deploy_tag=`./build.py log --log build --env sbs-config.json |grep image_tag|awk '{print $5}'|awk -F'-' '{print $2}'`
echo build.py log
./build.py log --log build --env sbs-config.json
tag_out=$(./build.py log --log build --env sbs-config.json|grep image_tag|awk -F- '{print $5}')
echo tag_out=$tag_out
image_tag=$(echo $tag_out)
echo image_tag=$image_tag
echo deploy_tag=$deploy_tag
echo PWD
pwd

#Cleaning up orphan resources

ibmcloud hpvs instance-delete $BUILD_SERVER -f
sleep 10
reclamation_id=`ibmcloud resource reclamations|grep SCHEDULED|awk '{print $1}'`
ibmcloud resource reclamation-delete $reclamation_id -f
#ibmcloud cr namespace-rm $CR_NAME -f

#Artifacts

mkdir /github/workspace/guardian
cp sbs.enc /github/workspace/guardian/
echo "# Launch application as an HPVS instance" > /github/workspace/guardian/deploy-instructions.md
echo " " >> /github/workspace/guardian/deploy-instructions.md
echo "Login to IBM cloud via ibcmcloud cli" >> /github/workspace/guardian/deploy-instructions.md
echo " " >> /github/workspace/guardian/deploy-instructions.md
echo "Download the encrypted registration file \`sbs.enc\` for the image." >> /github/workspace/guardian/deploy-instructions.md
echo " " >> /github/workspace/guardian/deploy-instructions.md
echo "You need to make some changes in the command below:" >> /github/workspace/guardian/deploy-instructions.md
echo " " >> /github/workspace/guardian/deploy-instructions.md
echo "- You need to change `HPVS-NAME`" >> /github/workspace/guardian/deploy-instructions.md
echo "- You need to change `YOUR-LOCATION` to one of the locations as explained in the following paragraphs." >> /github/workspace/guardian/deploy-instructions.md
echo "    - If you logged in to the \`us-east\`, then choose one of these three locations: \`wdc04\`, \`wdc06\` or \`wdc07\`" >> /github/workspace/guardian/deploy-instructions.md
echo "    - If you logged in to the \`au-syd\`, then choose one of these three locations: \`syd01\`, \`syd04\` or \`syd05\`" >> /github/workspace/guardian/deploy-instructions.md
echo "    - If you logged in to the \`eu-de\`, then choose one of these three locations: \`fra02\`, \`fra04\` or \`fra05\`" >> /github/workspace/guardian/deploy-instructions.md
echo " " >> /github/workspace/guardian/deploy-instructions.md
echo "Add parametrs to environment variables:" >> /github/workspace/guardian/deploy-instructions.md
echo " " >> /github/workspace/guardian/deploy-instructions.md
echo "- \`INSTANCE_NAME\`" >> /github/workspace/guardian/deploy-instructions.md
echo "- \`LOGGING_ELASTIC_INDEX_PREFIX\`" >> /github/workspace/guardian/deploy-instructions.md
echo "- \`LOGGING_ELASTIC_NODE_URLS\`" >> /github/workspace/guardian/deploy-instructions.md
echo " " >> /github/workspace/guardian/deploy-instructions.md
echo " or leave them empty" >> /github/workspace/guardian/deploy-instructions.md
echo " " >> /github/workspace/guardian/deploy-instructions.md
echo "Launch application:" >> /github/workspace/guardian/deploy-instructions.md
echo " " >> /github/workspace/guardian/deploy-instructions.md
echo "\`\`\`bash" >> /github/workspace/guardian/deploy-instructions.md
echo "ibmcloud hpvs instance-create HPVS-NAME entry YOUR-LOCATION  --rd-path sbs.enc -i $RELEASE_VERSION-$deploy_tag -e JAVA_OPTS="-Xms64m -Xmx2048m" -e "INSTANCE_NAME"="" -e "LOGGING_ELASTIC_INDEX_PREFIX"="" -e "LOGGING_ELASTIC_NODE_URLS"=""  >> /github/workspace/guardian/deploy-instructions.md
echo "\`\`\`" >> /github/workspace/guardian/deploy-instructions.md
ls -la /github/workspace/guardian/

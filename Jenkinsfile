node {
   def artServer = Artifactory.server('jfrogjd')
   artServer.credentialsId='jfrogjd.jfrog.io'
   def buildInfo = Artifactory.newBuildInfo()
   
dir('swampupdemo') {
   // Mark the code checkout 'stage'....
   stage('Checkout Docker') {

   // Get some code from a GitHub repository
   git url: 'https://github.com/jldeen/swampup2017'
   }
   
    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'jfrogjd.jfrog.io',
    usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD']]) {
    def uname=env.USERNAME
    def pw=env.PASSWORD
    artServer.username=uname
    artServer.password=pw
    sh 'echo JFrog Artifactory credentials applied'

stage('Azure Login') {
    // az creds
        withCredentials([usernamePassword(credentialsId: 'spn_pw', passwordVariable: 'pass', usernameVariable: 'spn'), string(credentialsId: 'tenant', variable: 'tenantId')]){

    // az login
    sh "az login --service-principal -u ${spn} -p ${pass} --tenant ${tenantId}" 

    // az Docker env variables
    env.azDockerHost=':2375'
    env.serviceName='containerservice-swampupdemo'
    env.resource='swampupdemo'
    env.masterFQDN = sh(script: "az acs show -n ${env.serviceName} -g ${env.resource} | jq -r '.masterProfile.fqdn'", returnStdout: true).trim()
    env.agentsFQDN = sh(script: "az acs show -n ${env.serviceName} -g ${env.resource} | jq -r '.agentPoolProfiles[0].fqdn'", returnStdout: true).trim()

    sh "echo masterFQDN is ${env.masterFQDN}"
    sh "echo agentsFQDN is ${env.agentsFQDN}"

    sh 'echo Azure credentials applied'
 
   }

   // Build and Deploy to Artifactory 'stage'... 
   stage('Build and Deploy') {
        def tagName='jfrogjd-docker-prod.jfrog.io/swampupdemo:'+env.BUILD_NUMBER
        docker.build(tagName)
        def artDocker= Artifactory.docker(uname, pw)
        artDocker.push(tagName, 'docker-prod', buildInfo)
        buildInfo.env.collect()
        artServer.publishBuildInfo(buildInfo)
   }

   stage('Open SSH Tunnel to Azure Swarm Cluster') {
       // Open SSH Tunnel to ACS Cluster
        sshagent(['acs_key']) {
            sh 'ssh -fNL 2375:localhost:2375 -p 2200 jldeen@swampupdemomgmt.southcentralus.cloudapp.azure.com -o StrictHostKeyChecking=no -o ServerAliveInterval=240 && echo "ACS SSH Tunnel successfully opened..."'
        }
   }

    // Pull, Run, and Test on ACS 'stage'... 
   stage('ACS Docker Pull and Run') {
       // Set env variable for stage for SSH ACS Tunnel
        env.DOCKER_HOST=env.azDockerHost
            sh 'echo "DOCKER_HOST is $DOCKER_HOST"'
            sh 'docker info'
            def imageName='jfrogjd-docker-prod.jfrog.io/swampupdemo'+':'+env.BUILD_NUMBER
            sh "docker login jfrogjd-docker-prod.jfrog.io -u ${uname} -p ${pw}"
            sh "docker pull ${imageName}"
            sh "docker run -d --name swampup-demo -p 80:8000 ${imageName}"

    stage('Artifactory Properties') {
           // Promote to latest build
            sh """curl -i -u ${uname}:${pw} -H \'Content-Type:application/json\' -XPOST https://jfrogjd.jfrog.io/jfrogjd/api/docker/docker-prod/v2/promote -d \'{"dockerRepository": "swampupdemo","tag": "\'${BUILD_NUMBER}\'","targetRepo": "docker-prod","targetTag": "latest","copy":true}\'
            """
            // Current Build Properties
            sh "echo 'applying build properties' && curl -i -u ${uname}:${pw} -XPUT -d '' https://jfrogjd.jfrog.io/jfrogjd/api/storage/docker-prod/swampupdemo/${env.BUILD_NUMBER}?properties=artifactory.refersToVersion=${env.BUILD_NUMBER}\\;azure.masterFQDN=${env.masterFQDN}\\;azure.agentsFQDN=${env.agentsFQDN} && echo 'artifactory.refersToVersion, azure.masterFQDN, azure.agentsFQDN properties applied'"
            // Latest Properties
            sh "echo 'applying latest tag properties' && curl -i -u ${uname}:${pw} -XPUT -d '' https://jfrogjd.jfrog.io/jfrogjd/api/storage/docker-prod/swampupdemo/latest?properties=artifactory.refersToVersion=${env.BUILD_NUMBER}\\;azure.masterFQDN=${env.masterFQDN}\\;azure.agentsFQDN=${env.agentsFQDN} && echo 'artifactory.refersToVersion, azure.masterFQDN, azure.agentsFQDN properties applied'"
   }
   }
}
}
}
}
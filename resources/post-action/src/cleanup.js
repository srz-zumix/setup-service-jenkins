const exec = require('@actions/exec');
const process = require('process');

docker_ids = process.env['JENKINS_AGENT_IDS'].trim().split(' ');

async function stop_container(docker_id) {
    console.log("Print service container logs: " + docker_id);
    exec.exec('docker', ['logs', '--details', docker_id]);
    console.log("Stop and remove container: " + docker_id);
    await exec.exec('docker', ['container', 'rm', '--force', docker_id]);
}

for (const docker_id of docker_ids) {
    stop_container(docker_id);
}


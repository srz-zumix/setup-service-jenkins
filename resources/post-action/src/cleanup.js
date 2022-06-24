const core = require('@actions/core');
const exec = require('@actions/exec');
const process = require('process');

docker_ids = (process.env['JENKINS_AGENT_IDS'] || '').trim().split(' ');

async function stop_container(docker_id) {
    try {
        console.log("Print service container logs: " + docker_id);
        await exec.exec('docker', ['logs', '--details', docker_id]);
        console.log("Stop and remove container: " + docker_id);
        await exec.exec('docker', ['rm', '--force', docker_id]);
    } catch (error) {
        core.warning(error.message);
    }
}

async function stop_containers() {
    for (const docker_id of docker_ids) {
        await stop_container(docker_id);
    }    
}

stop_containers()

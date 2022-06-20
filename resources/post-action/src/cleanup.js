const exec = require('@actions/exec');
const process = require('process');

console.log(process.env['JENKINS_AGENT_IDS']);

exec.exec('docker', ['ps', '-a']);

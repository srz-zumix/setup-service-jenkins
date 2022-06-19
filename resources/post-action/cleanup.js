const exec = require('@actions/exec');

await exec.exec('docker', ['ps', '-a']);

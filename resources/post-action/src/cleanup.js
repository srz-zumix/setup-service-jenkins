const exec = require('@actions/exec');

exec.exec('docker', ['ps', '-a']);

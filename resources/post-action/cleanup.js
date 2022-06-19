const core = require('@actions/core');
const github = require('@actions/github');
const exec = require('@actions/exec');

try {
    // Get the JSON webhook payload for the event that triggered the workflow
  const payload = JSON.stringify(github.context.payload, undefined, 2)
  console.log(`The event payload: ${payload}`);

  await exec.exec('docker', ['ps', '-a']);
} catch (error) {
  core.setFailed(error.message);
}

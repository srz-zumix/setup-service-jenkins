import java.io.*
import jenkins.model.*
import jenkins.install.*

def instance = Jenkins.get()
if (!instance.installState.isSetupComplete()) {
    println '--> Neutering SetupWizard'
    instance.setInstallState(InstallState.INITIAL_SETUP_COMPLETED)
    InstallState.INITIAL_SETUP_COMPLETED.initializeState()
    instance.save()
}

// def version = instance.getVersion()
// new File("/usr/share/jenkins/ref/jenkins.install.UpgradeWizard.state").text = version
// new File("/usr/share/jenkins/ref/jenkins.install.InstallUtil.lastExecVersion").text = version

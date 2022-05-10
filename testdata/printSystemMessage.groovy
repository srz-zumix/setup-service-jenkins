#!/usr/bin/groovy

args.each { 
    println it
}

println jenkins.model.Jenkins.get().getSystemMessage()

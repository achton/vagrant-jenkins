# site.pp

import 'nodes'
import 'settings'

# Define global paths and file ownership
Exec { path => '/usr/sbin/:/sbin:/usr/bin:/bin' }
File { owner => 'root', group => 'root' }
Ssh_authorized_key { ensure => present }

# Create stages to make sure apt-get update is run before all other tasks
# TODO: Is this needed now? (apt-get not used on centos.)
stage { 'requirements': before => Stage['main'] }
stage { 'bootstrap': before => Stage['requirements'] }

# TODO: Documentation???
class jenkinsci::bootstrap {
  # we need an updated list of sources before we can apply the configuration
  # TODO: Do we need to update anything here for yum/centos?
}

# TODO Documetation???
class jenkinsci::requirements {
  # Retrieve jenkins package repo file.
  exec { 'jenkins-repo-download':
    command => 'wget -O jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo',
    creates => '/etc/yum.repos.d/jenkins.repo',
    cwd     => '/etc/yum.repos.d',
  }

  # Import the repo key to the package manager
  exec { 'jenkins-repo-import':
    command => 'rpm --import http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key',
    require => Exec['jenkins-repo-download'],
  }

  # Install jenkins though yum.
  package { 'jenkins':
    ensure => present,
    require => Exec['jenkins-repo-import'],
  }

  # TODO install maria db for centos - used for? (simpletest?)
}

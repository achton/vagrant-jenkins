# site.pp

import 'nodes'
import 'settings'

# define global paths and file ownership
Exec { path => '/usr/sbin/:/sbin:/usr/bin:/bin' }
File { owner => 'root', group => 'root' }
Ssh_authorized_key { ensure => present }

# create a stage to make sure apt-get update is run before all other tasks
stage { 'requirements': before => Stage['main'] }
stage { 'bootstrap': before => Stage['requirements'] }

class jenkinsci::bootstrap {
  # we need an updated list of sources before we can apply the configuration
  # TODO: Do we need to update anything here for yum/centos?
}

class jenkinsci::requirements {
  # retrieve jenkins package repo file.
  exec { 'jenkins-repo-download':
    command => 'wget -O jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo',
    creates => '/etc/yum.repos.d/jenkins.repo',
    cwd     => '/etc/yum.repos.d',
  }

  # import the repo key to the package manager
  exec { 'jenkins-repo-import':
    command => 'rpm --import http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key',
    require => Exec['jenkins-repo-download'],
  }

  # install (yum install jenkins)
  package { 'jenkins':
    ensure => present,
    require => Exec['jenkins-repo-import'],
  }
  # TODO install maria db for centos
}

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
  if $operatingsystem == 'ubuntu' {
    exec { 'jenkins_apt_update':
     command => '/usr/bin/apt-get update',
    }
  }
}

class jenkinsci::requirements {
  case $operatingsystem {
    ubuntu: {
      apt::source { 'jenkins':
        location => 'http://pkg.jenkins-ci.org/debian',
        release => '',
        repos => 'binary/',
        key => 'D50582E6',
        key_server => 'http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key',
        include_src => false,
      }

      apt::source { 'mariadb':
        location => 'http://ftp.osuosl.org/pub/mariadb/repo/5.5/ubuntu',
        release => 'precise',
        repos => 'main',
        key => '1BB943DB',
        include_src => true,
      }
    }
    centos: {
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
    default: { fail("Unrecognized operating system for webserver for htop") }
  }
}

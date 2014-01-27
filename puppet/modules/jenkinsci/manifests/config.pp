# == Class: jenkinsci::config
#
#
#
# === Examples
#
#   class { 'jenkinsci::config': }
#
class jenkinsci::config(
  $slaves = undef
) {

  file { '/var/lib/jenkins/config.xml':
    content => template('jenkinsci/config.erb'),
    owner => jenkins,
    group => $operatingsystem ? {
      centos  => 'nobody',
      ubuntu  => 'nogroup',
      default => undef,
    },
    require => Package['jenkins'],
  }

  file { '/var/lib/jenkins/credentials.xml':
    source  => 'puppet:///modules/jenkinsci/credentials.xml',
    owner => jenkins,
    group => $operatingsystem ? {
      centos  => 'nobody',
      ubuntu  => 'nogroup',
      default => undef,
    },
    require => Package['jenkins'],
  }

}

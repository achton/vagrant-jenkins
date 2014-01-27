# == Class: jenkinsci
#
# This class installs the Jenkins continuous integration server.
#
# === Parameters
#
# [*jenkins_user*]
#   The username of the jenkins user. Defaults to 'jenkinsci'.
#
# [*jenkins_groups*]
#   The group of jenkins. Defaults to 'nogroup'.
#
# [*version*]
#   The version of the package to install. Takes the same arguments as the
#   'ensure' parameter. Defaults to 'present'.
#
# === Examples
#
#   class { 'jenkinsci': }
#
class jenkinsci(
  $jenkinsci_user  = 'UNSET',
  $jenkinsci_group = 'UNSET',
  $jenkinsci_mail  = 'jenkinsci@example.com',
  $version       = present
) {
  include jenkinsci::params

  $jenkinsci_user_real = $jenkinsci_user ? {
    'UNSET' => $jenkinsci::params::user,
    default => $jenkinsci_user,
  }

  $jenkinsci_group_real = $jenkinsci_group ? {
    'UNSET' => $jenkinsci::params::group,
    default => $jenkinsci_group,
  }

#  if ! defined(Apt::Source['jenkinsci']) {
#    apt::source { 'jenkinsci':
#      location    => 'http://pkg.jenkins-ci.org/debian',
#      release     => '',
#      repos       => 'binary/',
#      key         => 'D50582E6',
#      key_server  => 'http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key',
#      include_src => false,
#    }
#  }

#  package { 'jenkinsci':
#    ensure  => $version,
#    require => Apt::Source['jenkinsci'],
#  }

  service { 'jenkins':
    ensure  => running,
    enable  => true,
    require => Package['jenkins'],
  }

  file { '/var/lib/jenkins/.gitconfig':
    content => template('jenkinsci/gitconfig.erb'),
    owner   => $jenkinsci_user_real,
    group   => $jenkinsci_group_real,
    require => Package['jenkins'],
  }
}

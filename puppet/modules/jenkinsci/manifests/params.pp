# == Class: jenkins::params
#
# Shared parameters for the Jenkins module.
#
class jenkinsci::params {
  $user  = 'jenkins'
  $group = $operatingsystem ? {
      centos  => 'nobody',
      ubuntu  => 'nogroup',
      default => undef,
    }
}

# == Define: jenkins::plugin
#
# Use this resource type to install Jenkins plugins.
#
# === Parameters
#
# [*repository*]
#   The Git repository containing the job definition. Mandatory.
#
# [*jenkins_user*]
#   The username of the jenkins user. Defaults to 'jenkins'.
#
# [*jenkins_groups*]
#   The group of jenkins. Defaults to 'nogroup'.
#
# === Examples
#
#   jenkins::plugin { 'phing': }
#
define jenkinsci::plugin(
  $plugin_name   = $title,
  $version       = 'UNSET',
  $jenkinsci_user  = 'UNSET',
  $jenkinsci_group = 'UNSET'
) {
  $jenkinsci_user_real = $jenkinsci_user ? {
    'UNSET' => $jenkinsci::params::user,
    default => $jenkinsci_user,
  }

  $jenkinsci_group_real = $jenkinsci_group ? {
    'UNSET' => $jenkinsci::params::group,
    default => $jenkinsci_group,
  }

  $plugin_name_real  = "${plugin_name}.hpi"
  $plugin_dir        = '/var/lib/jenkins/plugins'
  $plugin_parent_dir = '/var/lib/jenkins'

  if $version != 'UNSET' {
    $base_url = "http://updates.jenkins-ci.org/download/plugins/${name}/${version}/"
  }
  else {
    $base_url = 'http://updates.jenkins-ci.org/latest/'
  }

  if !defined(File[$plugin_dir]) {
    file { [$plugin_parent_dir, $plugin_dir]:
      ensure  => directory,
      owner   => $jenkinsci_user_real,
      group   => $jenkinsci_group_real,
      require => Package['jenkins'],
    }
  }

  exec { "jenkinsci-plugin-download-${name}":
    command => "wget --no-check-certificate ${base_url}${plugin_name_real}",
    cwd     => $plugin_dir,
    user    => $jenkinsci_user_real,
    unless  => "test -f ${plugin_dir}/${plugin_name_real}",
    notify  => Service['jenkins'],
    require => [Package['jenkins'], File[$plugin_dir]],
  }

  if $plugin_name == 'seleniumhq' {
    file { '/var/lib/jenkins/hudson.plugins.seleniumhq.SeleniumhqBuilder.xml':
      source  => 'puppet:///modules/jenkins/config.selenium.xml',
      owner   => $jenkinsci_user_real,
      group   => $jenkinsci_group_real,
      require => Package['jenkins'],
    }
  }
}

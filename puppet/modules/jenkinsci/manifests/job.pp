# == Define: jenkins::job
#
# This resource type adds a Jenkins job template.
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
#   jenkins::job { 'job-template':
#     repository => 'git://github.com/jobs/job-template.git',
#   }
#
define jenkinsci::job(
  $job_name      = $title,
  $repository    = 'UNSET',
  $branch        = 'UNSET',
  $jenkinsci_user  = 'UNSET',
  $jenkinsci_group = 'UNSET'
) {
  if $repository == 'UNSET' {
    fail('repository parameter is required')
  }

  $jenkinsci_branch_real = $branch ? {
    'UNSET' => '',
    default => "-b $branch",
  }

  $jenkinsci_user_real = $jenkinsci_user ? {
    'UNSET' => $jenkinsci::params::user,
    default => $jenkinsci_user,
  }

  $jenkinsci_group_real = $jenkinsci_group ? {
    'UNSET' => $jenkinsci::params::group,
    default => $jenkinsci_group,
  }

  exec { "jenkinsci-job-${job_name}":
    command => "git clone ${jenkinsci_branch_real} ${repository} ${job_name} && chown -R ${jenkinsci_user_real}:${jenkinsci_group_real} ${job_name}",
    cwd     => '/var/lib/jenkins/jobs',
    creates => "/var/lib/jenkins/jobs/${job_name}",
    require => Package['jenkins'],
  }
}

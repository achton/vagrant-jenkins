class ntp {
  package { 'ntp':
    ensure => present,
  }

  $ntp_service = $operatingsystem ? {
     ubuntu => "ntp",
     centos => "ntpd",
  }

  service { $ntp_service:
    ensure => running,
    require => Package['ntp'],
  }
}

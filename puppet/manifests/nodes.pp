# nodes.pp

node "basenode" {
  # Update system packages
  exec { 'update-all-packages':
    command => '/usr/bin/yum update --skip-broken -y --exclude=kernel\*'
  }

  # Log outgoing calls.
  #exec { 'log-outgoing-traffic':
  #  command => 'iptables -I OUTPUT 1 -p tcp -j LOG',
  #}

  # Disable iptables to allow incomming trafic
  # TODO IMPORTANT: remove before setting if for real as this is a security risk
  service { 'iptables':
    ensure => 'stopped',
  }

  class { 'jenkinsci::bootstrap':
    stage => 'bootstrap',
  }

  class { 'git':
    stage => 'requirements',
  }

  # Time Synchronization across servers.
  class { 'ntp':
    stage => 'requirements',
  }

  # Interactive processes viewer
  # TODO: check that jenkins is using it.
  exec { 'rpm-download-rpmforge':
    command => "wget pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.2-2.el5.rf.${architecture}.rpm",
    creates => "/tmp/rpmforge-release-0.5.2-2.el5.rf.${architecture}.rpm", # prevents it from being downloaded if it already exists.
    cwd     => '/tmp',
  }

  exec { 'rpm-add-rpmforge':
    command => "rpm -Uhv rpmforge-release-0.5.2-2.el5.rf.${architecture}.rpm",
    cwd     => '/tmp',
    require => Exec['rpm-download-rpmforge'],
    unless  => "rpm -qa | grep rpmforge" # Do not install if already installed.
  }

  package { 'htop':
    ensure => present,
    require => Exec['rpm-add-rpmforge'],
  }

  # ncurses disk usage viewer
  # TODO find ncdu installation method for centos
}

node "jenkins-master" inherits "basenode" {
  # Install Java, used by Jenkins
  package {"java-1.6.0-openjdk":
    ensure => installed,
  }

  class { 'jenkinsci::requirements':
    stage => 'requirements',
  }

  # Install jenkins and all required plugins
  class { 'jenkinsci':
    version => 1.549
  }

  # Dependencies for plugins are listed on the plugins page on wiki.jenkinsci.org
  jenkinsci::plugin { 'analysis-collector': }
  jenkinsci::plugin { 'analysis-core': }
  jenkinsci::plugin { 'ansicolor': }
  jenkinsci::plugin { 'build-timeout': }
  jenkinsci::plugin { 'checkstyle': }
  jenkinsci::plugin { 'claim': }
  jenkinsci::plugin { 'compact-columns': }
  jenkinsci::plugin { 'console-column-plugin': }
  jenkinsci::plugin { 'dashboard-view': }
  jenkinsci::plugin { 'disk-usage': }
  jenkinsci::plugin { 'dry': }
  jenkinsci::plugin { 'dynamicparameter': }
  jenkinsci::plugin { 'email-ext': }
  jenkinsci::plugin { 'envinject': }
  jenkinsci::plugin { 'favorite': }
  # Define dependencies to ensure plugins are up to date.
  jenkinsci::plugin {
    'git':
      version => "2.0";
  }
  jenkinsci::plugin {
    "git-client" :
      version => "1.4.5";
  }
  jenkinsci::plugin {
    "ssh-credentials" :
      version => "1.5.1";
  }
  jenkinsci::plugin {
    "ssh-agent" :
      version => "1.3";
  }
  jenkinsci::plugin {
    "credentials" :
      version => "1.8.3";
  }
  jenkinsci::plugin {
    "scm-api" :
      version => "0.1";
  }
  jenkinsci::plugin { 'jenkinswalldisplay': }
  jenkinsci::plugin { 'jobConfigHistory': }
  jenkinsci::plugin { 'log-parser': }
  jenkinsci::plugin { 'multiple-scms': }
  jenkinsci::plugin { 'performance': }
  jenkinsci::plugin { 'phing': }
  jenkinsci::plugin { 'plot': }
  jenkinsci::plugin { 'pmd': }
  jenkinsci::plugin { 'project-stats-plugin': }
  jenkinsci::plugin { 'tasks': }
  jenkinsci::plugin { 'token-macro': }
  jenkinsci::plugin { 'view-job-filters': }
  jenkinsci::plugin { 'warnings': }
  jenkinsci::plugin { 'xvfb': }
  jenkinsci::plugin { 'doxygen': }
  jenkinsci::plugin { 'role-strategy': }
#  jenkinsci::plugin { 'selenium': } # TODO: use this when it becomes stable

  # Configure Jenkins master to know the slaves
  class { 'jenkinsci::config':
    slaves => [
      {
        name => 'phpqa.local',
        description => 'A slave optimized for doing static code analysis of PHP projects.',
        labels => 'phpqa',
        host => '33.33.33.111',
        port => '22',
        path => '/home/jenkins/ci',
        username => 'jenkins',
        privatekey => '/var/lib/jenkins/.ssh/id_rsa',
        executors => 2,
      },
#      {
#        name => 'simpletest.local',
#        description => 'A slave optimized for running Drupal simpletests.',
#        labels => 'drupal',
#        host => '33.33.33.112',
#        port => '22',
#        path => '/home/jenkins/ci',
#        username => 'jenkins',
#        privatekey => '/var/lib/jenkins/.ssh/id_rsa',
#        executors => 2,
#      },
#      {
#        name => 'selenium.local',
#        description => 'A slave optimized for running Selenium-based tests.',
#        labels => 'selenium',
#        host => '33.33.33.113',
#        port => '22',
#        path => '/home/jenkins/ci',
#        username => 'jenkins',
#        privatekey => '/var/lib/jenkins/.ssh/id_rsa',
#        executors => 2,
#      },
    ],
    # Restart Jenkins to registre the new configuration.
    notify => Service['jenkins'],
  }

  # This is necessary to render graphs
  package { 'dejavu-sans-fonts':
    ensure => installed,
  }

  # Set SSH keys. This is used to identify with other services such as git.
  file { '/var/lib/jenkins/.ssh':
    ensure => directory,
    owner => jenkins,
    group => nobody,
    mode => 0700,
    require => Package['jenkins'],
  }

  file { '/var/lib/jenkins/.ssh/id_rsa':
    content => $ssh_private_key,
    owner => jenkins,
    group => nobody,
    mode => 0600,
    require => File['/var/lib/jenkins/.ssh'],
  }

  file { '/var/lib/jenkins/.ssh/id_rsa.pub':
    content => $ssh_public_key,
    owner => jenkins,
    group => nobody,
    mode => 0644,
    require => File['/var/lib/jenkins/.ssh'],
  }

  # Disable SSH host verification. Without this Jenkins jobs will fail.
  file { '/var/lib/jenkins/.ssh/config':
    content => "UserKnownHostsFile=/dev/null\nStrictHostKeyChecking=no",
    owner => jenkins,
    group => nobody,
    mode => 0644,
    require => File['/var/lib/jenkins/.ssh'],
  }

}

node "jenkins-slave" inherits "basenode" {
  # Install Java, used by Jenkins.
  package {"java-1.6.0-openjdk":
    ensure => installed,
  }

  # Add user with home directory.
  user { 'jenkins':
    name => 'jenkins',
    shell => '/bin/bash',
    managehome => true,
    ensure => present,
  }

  # Allow servers with the given public key to connect as this user.
  # (Used by Jenkins master)
  ssh_authorized_key { 'jenkinsci':
    user => 'jenkins',
    type => 'ssh-rsa',
    key => $ssh_public_key,
  }

  # Setup jenkins working directory.
  file { '/home/jenkins/ci':
    ensure => directory,
    owner => 'jenkins',
    group => 'jenkins',
    require => User['jenkins'],
  }

  # Configure git for jenkins user.
  file { '/home/jenkins/.gitconfig':
    content => "[user]\n  email = jenkinsci@git.example.dk\n  name = Jenkinsci Git",
    owner => 'jenkins',
    group => 'jenkins',
    require => User['jenkins'],
  }

  # Disable SSH host verification. Without this Jenkins jobs will fail.
  file { '/home/jenkins/.ssh/config':
    content => "UserKnownHostsFile=/dev/null\nStrictHostKeyChecking=no",
    owner => jenkins,
    group => nobody,
    mode => 0644,
    require => File['/home/jenkins/.ssh'],
  }

  # Set SSH keys. This is used to identify with other services such as git.
  file { '/home/jenkins/.ssh':
    ensure => directory,
    owner => jenkins,
    group => nobody,
    mode => 0700,
    require => User['jenkins'],
  }

  file { '/home/jenkins/.ssh/id_rsa':
    content => $ssh_private_key,
    owner => jenkins,
    group => nobody,
    mode => 0600,
    require => File['/home/jenkins/.ssh'],
  }

  file { '/home/jenkins/.ssh/id_rsa.pub':
    content => "ssh-rsa ${ssh_public_key}",
    owner => jenkins,
    group => nobody,
    mode => 0644,
    require => File['/home/jenkins/.ssh'],
  }

}

# TODO: Update master.local to match your machine name.
node "master.local" inherits "jenkins-master" {

  # This is necessary to make it possible to configure jobs using xvfb
  package {"xorg-x11-server-Xvfb":
    ensure => installed,
  }

  # Install postfix to make it possible for jenkins to notify via mail
  package { 'postfix':
    ensure => present,
  }

  service { 'postfix':
    ensure  => running,
    require => Package['postfix'],
  }

  # Use apache as a proxy for jenkins TODO: if that's all, then it's not needed atm.
  class { 'apache': }

  # Install various job templates
  file { '/var/lib/jenkins/jobs':
    ensure => directory,
    owner => jenkins,
    group => jenkins,
  }

  jenkinsci::job { 'template-drupal-static-analysis':
    repository => 'git://github.com/troelsselch/jenkins-template-drupal-static-analysis.git',
    branch => 'develop',
    require => File['/var/lib/jenkins/jobs'],
  }
  #jenkinsci::job { 'template-drupal-simpletest':
  #  repository => 'git://github.com/wulff/jenkins-drupal-template.git',
  #  require => File['/var/lib/jenkins/jobs'],
  #}
  #jenkinsci::job { 'template-selenium':
  #  repository => 'git://github.com/wulff/jenkins-template-selenium.git',
  #  branch => 'develop',
  #  require => File['/var/lib/jenkins/jobs'],
  #}
}

# TODO: Update master.local to match your machine name.
node "phpqa.local" inherits "jenkins-slave" {
  # Install unzip.
  package { 'unzip':
    ensure => present,
  }

  # Install PHP.
  class { 'php': }

  # Install APC.
  package { 'php-pecl-apc':
    ensure => installed,
  }

  # Install GD module.
  php::module { 'gd': }

  # Install xdebug.
  exec { 'install-php-xdebug':
    command => 'pecl install xdebug',
    unless => 'pecl list | grep xdebug',
  }

  # Install Imagick
  package { 'ImageMagick-devel': }

  exec { 'install-php-imagick':
    command => 'pecl install imagick',
    unless => 'pecl list | grep imagick',
  }

  # Install PDO to add support for SQLite. TODO: What is this used for?
  exec { 'install-php-pdo':
    command => 'pecl install pdo',
    unless => 'pecl list | grep pdo',
  }

  # Install XML support - used to write CPD report
  package { 'php-xml': }

  # Install Doxygen.
  package { 'doxygen': }

  # Update DNS settings - avoid 10min calls for PEAR updates.
  exec { 'resolv-update':
    command => 'echo "options single-request-reopen" >> /etc/resolv.conf',
    before => Class['php::pear'],
  }

  # TODO: https://github.com/sebastianbergmann/phpcpd/issues/57
  # Install PEAR and then install QATools
  class { 'php::pear': } -> class { 'php::qatools': }

  # Install nodejs, used to install jshint and csslint
  class { 'nodejs':
    manage_repo  => true
  }

  # Add symlink. Nodejs is installed as "$ nodejs", but csslint/jshint uses "$ node"
  file { '/usr/bin/node':
    ensure => 'link',
    target => '/usr/bin/nodejs',
    require => Class['nodejs'],
  }

  # Install JSHint
  exec { 'install-jshint':
    command => '/usr/bin/npm install --global jshint@2.4.3', # global flag = install in global scope
    # Set strict-ssl false since it's an old nodejs.
    onlyif => '/usr/bin/npm config set strict-ssl false',
    require => File['/usr/bin/node'],
  }

  # Install CSSLint
  exec { 'install-csslint':
    command => '/usr/bin/npm install --global csslint',
    # Set strict-ssl false since it's an old nodejs.
    onlyif => '/usr/bin/npm config set strict-ssl false',
    require => File['/usr/bin/node'],
  }

  # Download Drupal codesniffer rules.
  exec { 'install-drupal-coder':
    command => 'git clone --branch 7.x-2.x http://git.drupal.org/project/coder.git /opt/coder',
    creates => '/opt/coder/coder_sniffer/Drupal/ruleset.xml',
  }

  # TODO: add a git pull to make sure the ruleset is up to date

  # Add symlink to allow CodeSniffer to use the Drupal rules.
  file { '/usr/share/pear/PHP/CodeSniffer/Standards/Drupal':
    ensure => link,
    target => '/opt/coder/coder_sniffer/Drupal',
    require => [Exec['install-drupal-coder'], Class['php::qatools']],
  }

}

# TODO: This node is not adjusted for CentOS.
node "simpletest.local" inherits "jenkins-slave" {

  class { 'jenkinsci::requirements':
    stage => 'requirements',
  }

  # configure a php-enabled apache server

  class { 'apache': }
  class { 'php': }
  apache::mod { 'php5': }
  apache::mod { 'rewrite': }
  apache::mod { 'vhost_alias': }

  php::pear::package { 'phing':
    repository => 'pear.phing.info',
  }

  class { 'ci::vhosts': }

  # TODO: Add dynamic vhost for /home/jenkins/ci/<jobname>/workspace
  #       http://httpd.apache.org/docs/2.2/vhosts/mass.html

  php::module { 'mysqlnd':
    restart => Service['apache2'],
    require => Class['mysql::server'],
  }

  # install the database server

  class { 'mysql::server':
    # FIXME: this doesn't seem to work with the latest 12.04 LTS
    #        see https://lists.launchpad.net/maria-discuss/msg00698.html
    # use the mysql module to install the mariadb packages
    # package_name     => 'mariadb-server',
    config_hash      => { 'root_password' => 'root' },
    # necessary because /sbin/status doesn't know about mysql on ubuntu
    service_provider => 'debian',
  }

  # add a drush task to phing

  file { '/usr/share/php/phing/tasks/drupal':
    ensure  => directory,
    require => Package["pear-pear.phing.info-phing"],
  }

  exec { 'download-phing-drush-task':
    command => 'wget https://raw.github.com/kasperg/phing-drush-task/master/DrushTask.php',
    cwd     => '/usr/share/php/phing/tasks/drupal',
    creates => '/usr/share/php/phing/tasks/drupal/DrushTask.php',
    require => File['/usr/share/php/phing/tasks/drupal'],
  }

}

# TODO: This node is not adjusted for CentOS.
# node "selenium.local" inherits "jenkins-slave" {
#   class { 'selenium': }

#   package { 'firefox':
#     ensure  => present,
#     require => Package['xvfb'],
#   }

#  package { 'chromium-browser':
#     ensure  => present,
#     require => Package['xvfb'],
#  }

#   class { 'php': }
#   php::module { 'curl': }
#   class { 'php::pear': } -> php::pear::package { 'phpunit':
#     repository => 'pear.phpunit.de',
#   }

#   exec { 'install-php-webdriver':
#     command => 'git clone https://github.com/facebook/php-webdriver.git /opt/php-webdriver',
#     creates => '/opt/php-webdriver/lib/WebDriver.php',
#   }
# }

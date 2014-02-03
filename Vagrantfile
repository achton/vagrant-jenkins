Vagrant::configure('2') do |config|
  # The base box this environment is built off of
  config.vm.box = 'centos-64-x64-vbox4210'

  # The url from where to fetch the base box if it doesn't exist
  config.vm.box_url = 'http://puppet-vagrant-boxes.puppetlabs.com/centos-64-x64-vbox4210.box'

  # Use puppet to provision packages
  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = 'puppet/manifests'
    puppet.manifest_file = 'site.pp'
    puppet.module_path = 'puppet/modules'
    puppet.options = '--verbose --debug'
  end

  # Setup master node
  config.vm.define :master, {:primary => true} do |master|
    # Configure network
    master.vm.hostname = 'master.local'
    master.vm.network :private_network, ip: '33.33.33.100'

    config.vm.provider 'virtualbox' do |v|
      v.name = 'Vagrant Jenkins - Master'
      v.customize ['modifyvm', :id, '--memory', 512]
    end
  end

  # Setup static phpqa node
  config.vm.define :phpqa do |phpqa|
    # cCnfigure network
    phpqa.vm.hostname = 'phpqa.local'
    phpqa.vm.network :private_network, ip: '33.33.33.111'

    config.vm.provider 'virtualbox' do |v|
      v.name = 'Vagrant Jenkins - PHP QA'
      v.customize ['modifyvm', :id, '--memory', 512]
    end
  end

  # Setup drupal simpletest node
  config.vm.define :simpletest do |simpletest|
    # Configure network
    simpletest.vm.hostname = 'simpletest.local'
    simpletest.vm.network :private_network, ip: '33.33.33.112'

      config.vm.provider 'virtualbox' do |v|
      v.name = 'Vagrant Jenkins - Drupal Simpletest'
      v.customize ['modifyvm', :id, '--memory', 512]
    end
  end

  # Setup selenium node
  config.vm.define :selenium do |selenium|
    # configure network
    selenium.vm.hostname = 'selenium.local'
    selenium.vm.network :private_network, ip: '33.33.33.113'

    config.vm.provider 'virtualbox' do |v|
      v.name = 'Vagrant Jenkins - Selenium'
      v.customize ['modifyvm', :id, '--memory', 512]
    end
  end
end

Vagrant::configure('2') do |config|
  # the base box this environment is built off of
  config.vm.box = 'precise32'

  # the url from where to fetch the base box if it doesn't exist
  config.vm.box_url = 'http://files.vagrantup.com/precise32.box'

  # use puppet to provision packages
  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = 'puppet/manifests'
    puppet.manifest_file = 'site.pp'
    puppet.module_path = 'puppet/modules'
    puppet.options = ['--verbose']
  end

  # setup master node
  config.vm.define :master, {:primary => true} do |master|
    # configure network
    master.vm.hostname = 'master.local'
    master.vm.network :private_network, ip: '33.33.33.200'

    config.vm.provider 'virtualbox' do |v|
      v.name = 'Vagrant Jenkins Ubuntu - Master'
      v.customize ['modifyvm', :id, '--memory', 512]
    end
  end

  # setup static phpqa node
  config.vm.define :phpqa do |phpqa|
    # configure network
    phpqa.vm.hostname = 'phpqa.local'
    phpqa.vm.network :private_network, ip: '33.33.33.211'

    config.vm.provider 'virtualbox' do |v|
      v.name = 'Vagrant Jenkins Ubuntu - PHP QA'
      v.customize ['modifyvm', :id, '--memory', 512]
    end
  end

  # setup drupal simpletest node
  config.vm.define :simpletest do |simpletest|
    # configure network
    simpletest.vm.hostname = 'simpletest.local'
    simpletest.vm.network :private_network, ip: '33.33.33.212'

      config.vm.provider 'virtualbox' do |v|
      v.name = 'Vagrant Jenkins Ubuntu - Drupal Simpletest'
      v.customize ['modifyvm', :id, '--memory', 512]
    end
  end

  # setup selenium node
  config.vm.define :selenium do |selenium|
    # configure network
    selenium.vm.hostname = 'selenium.local'
    selenium.vm.network :private_network, ip: '33.33.33.213'

    config.vm.provider 'virtualbox' do |v|
      v.name = 'Vagrant Jenkins Ubuntu - Selenium'
      v.customize ['modifyvm', :id, '--memory', 512]
    end
  end
end

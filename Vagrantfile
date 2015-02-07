Vagrant.configure('2') do |config|
  config.vm.box = 'hfm4/centos6'
  config.vm.provision :shell do |s|
    s.path = 'provision.sh'
    vms = %w(db app)
    s.args =  vms
  end
end

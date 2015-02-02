Vagrant.configure("2") do |config|
  config.vm.box = "hfm4/centos6"
  config.vm.synced_folder "./", "/home/vagrant/share"
  config.vm.provision :shell, :path => "provision.sh"
end

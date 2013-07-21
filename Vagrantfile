Vagrant.configure("2") do |config|
  config.vm.box = "centos64-base"
  config.vm.synced_folder "./", "/home/vagrant/share"
  config.vm.provision :shell, :path => "provision.sh"
end

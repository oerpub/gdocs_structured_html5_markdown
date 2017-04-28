# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-16.04"

  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # config.vm.network "private_network", ip: "192.168.33.10"

  # config.vm.synced_folder "../data", "/vagrant_data"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
  end

  config.vm.provision "shell", inline: <<-SHELL
    apt-get -qqy update
    apt-get install -qy python2.7 python-libxml2 python-libxslt1 python-pip
    apt-get install -qy blahtexml
    wget -nv -O /tmp/tidy-5.4.0-64bit.deb https://github.com/htacg/tidy-html5/releases/download/5.4.0/tidy-5.4.0-64bit.deb
    dpkg -i /tmp/tidy-5.4.0-64bit.deb
    rm /tmp/tidy-5.4.0-64bit.deb
    pip install --disable-pip-version-check -r /vagrant/requirements.txt
  SHELL
end

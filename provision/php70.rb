class Php70
  def Php70.configure(config, settings, scriptDir)
    config.vm.define :vmphp70 do |vmphp70|
      vmphp70.vm.provision "web", type: "shell", inline: 'bash /vagrant/provision/setup-php-7.0.sh'

      # Configure All Of The Configured Databases
      if (settings.has_key?("databases") and settings['databases'].to_a.any?)
          settings["databases"].each do |db|
            vmphp70.vm.provision "shell", run: 'always' do |s|
              s.name = "Creating MySQL Database"
              s.path = scriptDir + "/scripts/create-mysql.sh"
              s.args = [db]
            end
          end
      end

      # Clear nginx Virtual Hosts
      vmphp70.vm.provision :shell, path: scriptDir + "/scripts/clear-nginx.sh", run: 'always'

      # Set Up nginx Virtual Hosts
      if (settings.include? 'sites' and settings['sites'].to_a.any?)
        settings["sites"].each do |site|
          vmphp70.vm.provision "shell", run: 'always' do |s|
            s.name = "Creating virtual hosts to: " + site["map"]
            s.path = scriptDir + "/provision/create-nginx-virtual-hosts.sh"
            s.args = [site["map"], site["to"], site["port"] ||= "80", site["ssl"] ||= "443", "php7.0"]
          end
        end
      end

      # Create users
      if (settings.has_key?("users") and settings['users'].to_a.any?)
          settings["users"].each do |u|
            vmphp70.vm.provision "shell", run: 'always' do |s|
              if u['github_token'].nil? || u['github_token'].to_s.length != 40
                puts "Error: You must place REAL GitHub token into configuration:\n#{fileSettings}"
              else
                s.name = "Adding user: " + u["fullname"]
                s.path = scriptDir + "/scripts/add-user.sh"
                s.args = [u["username"], u["fullname"], u["email"], u["password"], u["github_token"]]
              end
            end
          end
      end

      # Local Machine Hosts
      #
      # If the Vagrant plugin hostsupdater (https://github.com/cogitatio/vagrant-hostsupdater) is
      # installed, the following will automatically configure your local machine's hosts file to
      # be aware of the domains specified below.
      if defined? VagrantPlugins::HostsUpdater and settings['sites'].to_a.any?
        vmphp70.hostsupdater.aliases = settings['sites'].map { |site| site['map'] }
      end

      # Restart services
      vmphp70.vm.provision :shell, path: scriptDir + "/provision/configure-php-7.0.sh", run: 'always'
      vmphp70.vm.provision :shell, path: scriptDir + "/scripts/restart-services-php-7.0.sh", run: 'always'
    end
  end
end

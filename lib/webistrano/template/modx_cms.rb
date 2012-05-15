module Webistrano
  module Template
    module ModxCms
      
      CONFIG = Webistrano::Template::PureFile::CONFIG.dup.merge({
        :db_server => "IP of the database server",
        :db_name => "Name of the database for the application",
        :db_username => "User of the database",
        :db_password => "Password for database user",
        :server_name => "URL for the application",
        :cms_username => "Initial Admin user for the CMS",
        :cms_password => "Password for the cms admin user",
        :cms_email => "Email for the cms admin user"

      }).freeze
      
      DESC = <<-'EOS'
        Template for use with MODX CMS
        The basic (re)start/stop tasks of Capistrano are overrided with NOP tasks.
      EOS
      
      TASKS = Webistrano::Template::Base::TASKS + <<-'EOS'
      
         namespace :deploy do
           task :restart, :roles => :app, :except => { :no_release => true } do
             # do nothing
           end

           task :start, :roles => :app, :except => { :no_release => true } do
             # do nothing
           end

           task :stop, :roles => :app, :except => { :no_release => true } do
             # do nothing
           end
         end

         namespace :modx do
          desc "Run the cli installation. Requires definition of :modx_config"
          task :install, :roles => :web do
            create_config
            run "php #{current_path}/setup/index.php --installmode=new --config=#{shared_path}/config.xml --core-path=#{current_path}/core/"
          end

          desc "Upgrade modx via the cli, currently NO BACKUPS are done, please do it manually"
          task :upgrade, :roles => :web do
            run "php #{deploy_to}/current/setup/index.php --installmode=upgrade --config=#{deploy_to}/shared/config.xml --core-path=#{current_path}/core/"
          end

          desc "Create config.xml"
          task :create_config, :roles => :web do
            config_xml =<<-EOF
              <modx>
                <database_type>mysql</database_type>
                  <database_server>#{db_server}</database_server>
                  <database>#{db_name}</database>
                  <database_user>#{db_username}</database_user>
                  <database_password>#{db_password}</database_password>
                  <database_connection_charset>utf8</database_connection_charset>
                  <database_charset>utf8</database_charset>
                  <database_collation>utf8_general_ci</database_collation>
                  <table_prefix>modx_</table_prefix>
                  <https_port>443</https_port>
                  <http_host>#{server_name}</http_host>
                  <cache_disabled>0</cache_disabled>

                  <!-- Set this to 1 if you are using MODX from Git or extracted it from the full MODX package to the server prior
                       to installation. -->
                  <inplace>0</inplace>
                  
                  <!-- Set this to 1 if you have manually extracted the core package from the file core/packages/core.transport.zip.
                       This will reduce the time it takes for the installation process on systems that do not allow the PHP time_limit
                       and Apache script execution time settings to be altered. -->
                  <unpacked>0</unpacked>

                  <!-- The language to install MODX for. This will set the default manager language to this. Use IANA codes. -->
                  <language>en</language>

                  <!-- Information for your administrator account -->
                  <cmsadmin>#{cms_username}</cmsadmin>
                  <cmspassword>#{cms_password}</cmspassword>
                  <cmsadminemail>#{cms_email}</cmsadminemail>

                  <!-- Paths for your MODX core directory -->
                  <core_path>#{current_path}/core/</core_path>

                  <!-- Paths for the default contexts that are installed. -->
                  <context_mgr_path>#{current_path}/manager/</context_mgr_path>
                  <context_mgr_url>/manager/</context_mgr_url>
                  <context_connectors_path>#{current_path}/connectors/</context_connectors_path>
                  <context_connectors_url>/connectors/</context_connectors_url>
                  <context_web_path>#{current_path}/</context_web_path>
                  <context_web_url>/</context_web_url>

                  <!-- Whether or not to remove the setup/ directory after installation. -->
                  <remove_setup_directory>1</remove_setup_directory>
              </modx>
            EOF

            put config_xml, "#{shared_path}/config.xml"
          end

          desc "Symlink config files, cache, logs"
          task :symlink, :roles => :web do
            run "mkdir -p #{shared_path}/system/core/config; mkdir -p #{shared_path}/system/manager; mkdir -p #{shared_path}/system/connectors; mkdir -p #{shared_path}/system/core/cache"
            run "rm -rf #{current_path}/core/config/config.inc.php #{current_path}/manager/config.core.php #{current_path}/connectors/config.core.php #{current_path}/core/cache"
            run "mkdir -p #{current_path}/core/config; ln -s #{shared_path}/system/core/config/config.inc.php #{current_path}/core/config/config.inc.php"
            run "ln -s #{shared_path}/system/manager/config.core.php #{current_path}/manager/config.core.php"
            run "ln -s #{shared_path}/system/connectors/config.core.php #{current_path}/connectors/config.core.php"
            run "ln -s #{shared_path}/config.core.php #{current_path}/config.core.php"
            run "ln -s #{shared_path}/system/core/cache #{current_path}/core/cache"
          end

          desc "Not IMPLEMENTED: Setup MODX Install"
          task :setup, :roles => :web do
            run "echo Stub for symlink and other setup specific to capistrano"
          end

          desc "NOT IMPLEMENTED: Backup modx installation"
          task :backup, :roles => :web do
            run "echo Need to implement"
          end

          after "deploy:create_symlink", "modx:symlink"
        end
      EOS
    
    end
  end
end
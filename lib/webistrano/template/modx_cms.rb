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
            run "php #{current_path}/www/setup/index.php --installmode=new --config=#{shared_path}/config.xml --core-path=#{current_path}/www/core/"
          end

          desc "Upgrade modx via the cli, currently NO BACKUPS are done, please do it manually"
          task :upgrade, :roles => :web do
            run "php #{current_path}/www/setup/index.php --installmode=upgrade --config=#{shared_path}/config.xml --core-path=#{current_path}/www/core/"
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
                  <core_path>#{current_path}/www/core/</core_path>

                  <!-- Paths for the default contexts that are installed. -->
                  <context_mgr_path>#{current_path}/www/manager/</context_mgr_path>
                  <context_mgr_url>/manager/</context_mgr_url>
                  <context_connectors_path>#{current_path}/www/connectors/</context_connectors_path>
                  <context_connectors_url>/connectors/</context_connectors_url>
                  <context_web_path>#{current_path}/www/</context_web_path>
                  <context_web_url>/</context_web_url>

                  <!-- Whether or not to remove the setup/ directory after installation. -->
                  <remove_setup_directory>1</remove_setup_directory>
              </modx>
            EOF

            put config_xml, "#{shared_path}/config.xml"
          end

          desc "Remove modx setup directory"
          task :remove_setup_directory, :roles => :web do
            run "rm -rf #{current_path}/www/setup"
          end

          desc "Symlink config files, cache, logs"
          task :symlink, :roles => :web do
            run "mkdir -p #{shared_path}/system/www/core/config; mkdir -p #{shared_path}/system/www/manager; mkdir -p #{shared_path}/system/www/connectors; mkdir -p #{shared_path}/system/www/core/cache"
            run "rm -rf #{current_path}/www/core/config/config.inc.php #{current_path}/www/manager/config.core.php #{current_path}/www/connectors/config.core.php #{current_path}/www/core/cache"
            run "mkdir -p #{current_path}/www/core/config; ln -s #{shared_path}/system/www/core/config/config.inc.php #{current_path}/www/core/config/config.inc.php"
            run "rm -rf #{current_path}/www/upload; mkdir -p #{shared_path}/system/www/upload; ln -s #{shared_path}/system/www/upload #{current_path}/www/upload"
            run "ln -s #{shared_path}/system/www/manager/config.core.php #{current_path}/www/manager/config.core.php"
            run "ln -s #{shared_path}/system/www/connectors/config.core.php #{current_path}/www/connectors/config.core.php"
            run "ln -s #{shared_path}/system/www/config.core.php #{current_path}/www/config.core.php"
            run "ln -s #{shared_path}/system/www/core/cache #{current_path}/www/core/cache"
          end

          desc "Remove everything from inside the MODx cache directories"
          task :clear_modx_cache, :reoles => :web do
            run "rm -rf #{shared_path}/system/www/core/cache/*"
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
          after "modx:symlink", "modx:clear_modx_cache"
        end
      EOS

    end
  end
end
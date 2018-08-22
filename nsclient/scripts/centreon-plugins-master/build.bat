set PERL_INSTALL_DIR=C:\Strawberry
set PP_INSTALL_DIR=C:\Perl64

chdir /d %~dp0
set PAR_VERBATIM=1

cmd /C %PP_INSTALL_DIR%\site\bin\pp --lib=centreon-plugins-master\ -o centreon_plugins.exe centreon-plugins-master\centreon_plugins.pl ^
--unicode ^
-X IO::Socket::INET6 ^
--link=%PERL_INSTALL_DIR%\c\bin\libxml2-2__.dll ^
--link=%PERL_INSTALL_DIR%\c\bin\libiconv-2__.dll ^
--link=%PERL_INSTALL_DIR%\c\bin\liblzma-5__.dll ^
--link=%PERL_INSTALL_DIR%\c\bin\zlib1__.dll ^
-M Win32::Job ^
-M centreon::plugins::script ^
-M apps::activedirectory::local::plugin ^
-M apps::activedirectory::local::mode::dcdiag ^
-M apps::activedirectory::local::mode::netdom ^
-M apps::iis::local::plugin ^
-M apps::iis::local::mode::listapplicationpools ^
-M apps::iis::local::mode::applicationpoolstate ^
-M apps::iis::local::mode::listsites ^
-M apps::iis::local::mode::webservicestatistics ^
-M apps::exchange::2010::local::plugin ^
-M apps::exchange::2010::local::mode::activesyncmailbox ^
-M apps::exchange::2010::local::mode::databases ^
-M apps::exchange::2010::local::mode::listdatabases ^
-M apps::exchange::2010::local::mode::imapmailbox ^
-M apps::exchange::2010::local::mode::mapimailbox ^
-M apps::exchange::2010::local::mode::outlookwebservices ^
-M apps::exchange::2010::local::mode::owamailbox ^
-M apps::exchange::2010::local::mode::queues ^
-M apps::exchange::2010::local::mode::replicationhealth ^
-M apps::exchange::2010::local::mode::services ^
-M centreon::common::powershell::exchange::2010::powershell ^
-M os::windows::local::plugin ^
-M os::windows::local::mode::ntp ^
-M apps::backup::veeam::local::plugin ^
-M apps::backup::veeam::local::mode::listjobs ^
-M apps::backup::veeam::local::mode::jobstatus ^
-M centreon::common::powershell::veeam::listjobs ^
-M centreon::common::powershell::veeam::jobstatus ^
-M Time::HiRes ^
-M network::netgear::mseries::snmp::plugin ^
-M network::netgear::mseries::snmp::mode::cpu ^
-M network::netgear::mseries::snmp::mode::hardware ^
-M network::netgear::mseries::snmp::mode::memory ^
-M network::netgear::mseries::snmp::mode::components::fan ^
-M network::netgear::mseries::snmp::mode::components::psu ^
-M network::netgear::mseries::snmp::mode::components::temperature ^
-M hardware::server::hp::ilo::xmlapi::plugin ^
-M hardware::server::hp::ilo::xmlapi::custom::api ^
-M hardware::server::hp::ilo::xmlapi::mode::hardware ^
-M hardware::server::hp::ilo::xmlapi::mode::components::battery ^
-M hardware::server::hp::ilo::xmlapi::mode::components::bios ^
-M hardware::server::hp::ilo::xmlapi::mode::components::cpu ^
-M hardware::server::hp::ilo::xmlapi::mode::components::ctrl ^
-M hardware::server::hp::ilo::xmlapi::mode::components::driveencl ^
-M hardware::server::hp::ilo::xmlapi::mode::components::fan ^
-M hardware::server::hp::ilo::xmlapi::mode::components::ldrive ^
-M hardware::server::hp::ilo::xmlapi::mode::components::memory ^
-M hardware::server::hp::ilo::xmlapi::mode::components::nic ^
-M hardware::server::hp::ilo::xmlapi::mode::components::pdrive ^
-M hardware::server::hp::ilo::xmlapi::mode::components::psu ^
-M hardware::server::hp::ilo::xmlapi::mode::components::temperature ^
-M hardware::server::hp::ilo::xmlapi::mode::components::vrm ^
-M centreon::plugins::templates::hardware ^
-M XML::Simple ^
-M IO::Socket::SSL ^
-M LWP::UserAgent ^
--verbose

pause
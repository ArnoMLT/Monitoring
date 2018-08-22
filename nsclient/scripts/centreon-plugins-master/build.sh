#set PERL_INSTALL_DIR=C:\Strawberry
#set PP_INSTALL_DIR=C:\Perl64

#chdir /d %~dp0
#set PAR_VERBATIM=1
PAR_VERBATIM=1



pp --lib=centreon-plugins-master -o centreon_plugins.exe centreon-plugins-master/centreon_plugins.pl \
--unicode \
-X IO::Socket::INET6 \
--link=/usr/i686-w64-mingw32/sys-root/mingw/bin/libxml2-2.dll \
--link=/usr/i686-w64-mingw32/sys-root/mingw/bin/iconv.dll \
--link=/usr/i686-w64-mingw32/sys-root/mingw/bin/liblzma-5.dll \
--link=/usr/i686-w64-mingw32/sys-root/mingw/bin/zlib1.dll \
--link=/usr/i686-w64-mingw32/sys-root/mingw/bin/zlib1.dll \
--link=C:/cygwin64/bin/cygnetsnmp-30.dll \
--link=C:/cygwin64/bin/cygcrypto-1.0.0.dll \
--link=C:/cygwin64/bin/cygz.dll \
--link=C:/cygwin64/lib/perl5/vendor_perl/5.26/x86_64-cygwin-threads/auto/Net/SSLeay/SSLeay.dll \
-M centreon::plugins::** \
-M hardware::server::dell::** \
-M hardware::server::fujitsu::snmp::** \
-M hardware::server::hp::proliant::snmp::** \
-M hardware::server::hp::ilo::xmlapi::** \
-M XML::Simple \
-M IO::Socket::SSL \
-M LWP::UserAgent \
-M network::sonicwall::** \
-M network::stormshield::** \
-M network::zyxel::** \
-M network::snmp_standard::** \
-M storage::synology::**





# --link=/lib/perl5/vendor_perl/5.26/x86_64-cygwin-threads/auto/NetSNMP/agent/agent.dll \
# --link=/lib/perl5/vendor_perl/5.26/x86_64-cygwin-threads/auto/NetSNMP/agent/default_store/default_store.dll \
# --link=/lib/perl5/vendor_perl/5.26/x86_64-cygwin-threads/auto/NetSNMP/ASN/ASN.dll \
# --link=/lib/perl5/vendor_perl/5.26/x86_64-cygwin-threads/auto/NetSNMP/agent/agent.dll \
# --link=/lib/perl5/vendor_perl/5.26/x86_64-cygwin-threads/auto/NetSNMP/default_store/default_store.dll \
# --link=/lib/perl5/vendor_perl/5.26/x86_64-cygwin-threads/auto/NetSNMP/OID/OID.dll \
# --link=/lib/perl5/vendor_perl/5.26/x86_64-cygwin-threads/auto/NetSNMP/TrapReceiver/TrapReceiver.dll \
# --link=/lib/perl5/vendor_perl/5.26/x86_64-cygwin-threads/auto/SNMP/SNMP.dll \

#-x --xargs="--plugin=hardware::server::hp::proliant::snmp::plugin --mode=hardware --hostname=hypervr2-itbs3 --snmp-version=2c --filter=pnic --filter=lnic --filter=idectl --filter=psu,1.1 --filter=ilo --filter=fan,1.4"


#--verbose

# -M XML::Simple \
# -M IO::Socket::SSL \
# -M LWP::UserAgent \
#pause
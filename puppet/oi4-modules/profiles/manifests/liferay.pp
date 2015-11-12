class profiles::liferay {
  $multicast_address = hiera('toas::portal:multicast_address')
  $db_address = hiera('toas::portal::db_address')
  $db_password = hiera('toas::portal::db_password')
  $tomcat_monitor_role_password = hiera('toas::portal::tomcat_monitor_role_password')
  $jvm_mem = hiera('toas::portal::jvm_mem', '2048')
  $jvm_perm = hiera('toas::portal::jvm_perm', '512')
  $extra_jvm_opts = hiera('toas::portal::extra_jvm_opts', undef)
  $extra_catalina_opts = hiera('toas::portal::extra_catalina_opts', undef)
  $oi_home = hiera('toas::oi_home', '/opt/openinfinity')

  file {"$oi_home/log/tomcat":
    ensure  => 'directory',
    owner   => 'oiuser',
    group   => 'oiuser',
    mode    => 755,
    require => [User["oiuser"], File["$oi_home/log"]],
  }->
  class {'oi4portal::install': 
  }->
  class {'oi4portal::config':
    portal_multicast_address            => $multicast_address,
    portal_db_address                   => $db_address,
    portal_db_password                  => $db_password,
    portal_tomcat_monitor_role_password => $tomcat_monitor_role_password,
    portal_extra_jvm_opts               => $extra_jvm_opts,
    portal_extra_catalina_opts          => $extra_catalina_opts,
    portal_jvmmem                       => $jvm_mem,
    portal_jvmperm                      => $jvm_perm,
  }->
  class {'oi4portal::service':
  }->
  class {'tomcat':
    catalina_home       => "$oi_home/tomcat",
    install_from_source => false,
    manage_user         => false,
    manage_group        => false,
    user                => 'oiuser',
    group               => 'oiuser',
  }
}

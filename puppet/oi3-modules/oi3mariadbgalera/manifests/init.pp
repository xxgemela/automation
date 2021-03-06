class oi3mariadbgalera ($rdbms_mysql_password = undef, $rdbms_innodb_buffer_size = undef, $galera_cluster_name = undef, $galera_cluster_address = undef, $galera_node_address = undef, $galera_node_name = undef, $toaspathversion = undef,$runningNumber = undef) inherits oi3variables {

  #include oi3mariadbgalera::service


  $bas_cluster_addresses = parsejson($bas_cluster_addresses_array)

  if $runningNumber == undef {
    $_memberid = $::runningNumber
  }
  else {
    $_memberid = $runningNumber
  }	
  if $toaspathversion == undef {
    $_toaspathversion = $::toaspathversion
  }
  else {
    $_toaspathversion = $toaspathversion
  }	
  if $rdbms_mysql_password == undef {
    $_rdbms_mysql_password = $::mysql_password
  }
  else {
    $_rdbms_mysql_password = $rdbms_mysql_password
  }
  if $rdbms_innodb_buffer_size == undef {
    $_rdbms_innodb_buffer_size = $::innodb_buffer_size
  }
  else {
    $_rdbms_innodb_buffer_size = $rdbms_innodb_buffer_size
  }
  if $galera_cluster_address == undef {
    $_galera_cluster_address = $::galera_cluster_address
  }
  else {
    $_galera_cluster_address = $galera_cluster_address
  }
  if $galera_node_address == undef {
    $_galera_node_address = $::galera_node_address
  }
  else {
    $_galera_node_address = $galera_node_address
  }
  if $galera_node_name == undef {
    $_galera_node_name = $::galera_node_name
  }
  else {
    $_galera_node_name = $galera_node_name
  }
  if $galera_cluster_name == undef {
    $_galera_cluster_name = $::galera_cluster_name
  }
  else {
    $_galera_cluster_name = $galera_cluster_name
  }
  
  ensure_resource('user', 'mysql', {
        home => "/opt/openinfinity/$_toaspathversion/rdbms/data",
        managehome => false,
        system => true,
        gid => 'mysql',
        before => Package['oi3-mariadb-galera'],
    })

    ensure_resource('group', 'mysql', {
        ensure => present
    })

    package { "oi3-mariadb-galera":
        ensure => present,
    }

# required in meta package now. left if debian problems  
#    if ($operatingsystem ==  'CentOS') or ($operatingsystem == 'RedHat') {
#       package { "socat":
#        ensure => present,
#        before => File["/opt/openinfinity/$_toaspathversion/rdbms"],
#       }
#    }

	file { "/opt/openinfinity/current":
	   ensure => 'link',
	   target => "/opt/openinfinity/$_toaspathversion",
	   require => File["/opt/openinfinity/$_toaspathversion"],	   
	   owner => "oiuser",
	   group => "oiuser",
	}
	
    file {"/opt/openinfinity/$_toaspathversion/rdbms":
        ensure => directory,
        owner => "mysql",
        group => "mysql",
        mode => 0775,
        require => File["/opt/openinfinity/$_toaspathversion"],
    } ->
    file {"/opt/openinfinity/$_toaspathversion/rdbms/data":
        ensure => directory,
        owner => "mysql",
        group => "mysql",
        mode => 0775,
    } ->
    file {$openInfinityConfPath:
        ensure => present,
        content => template("oi3mariadbgalera/server_my.cnf.erb"),
        owner => "root",
        group => "root",
        mode => 0644,
    } ->
    file {"/root/mysql_system_tables_data.sql":
        ensure => present,
        content => template("oi3mariadbgalera/mysql_system_tables_data.sql.erb"),
        owner => "root",
        group => "root",
        mode => 0640,
    } ->
    file {"/root/mysql_install_db":
        ensure => present,
        source => "puppet:///modules/oi3mariadbgalera/mysql_install_db",
        owner => "root",
        group => "root",
        mode => 0750,
    } ->
    exec {"create-mysql-database":
        creates => "/opt/openinfinity/$_toaspathversion/rdbms/data/mysql/user.frm",
        command => $createMariaDbDatabaseCommand,
        before  => File["/opt/openinfinity/$_toaspathversion/rdbms/initiated.flag"],
    } ->
    file { "/opt/openinfinity/$_toaspathversion/rdbms/initiated.flag":
      ensure => present,
      content => "Initiated",
      owner => "root",
      group => "root",
      mode => 0640,
    } 
  if $_memberid == 1 {
    
    # for debug output on the puppet master
    notice("First node acting as cluster initiator.")

    exec {"start-mysql-newcluster":
      creates   => "/opt/openinfinity/$_toaspathversion/rdbms/firststart.flag",
      command   => "/etc/init.d/mysql start --wsrep-new-cluster",
      user      => "root",
      logoutput => true,
      before    => File["/opt/openinfinity/$_toaspathversion/rdbms/firststart.flag"],
      require   => File["/opt/openinfinity/$_toaspathversion/rdbms/initiated.flag"],
    }

  } else {

    # for debug output on the puppet master
        notice("Cluster member node, dependent of cluster initiator.")

    exec {"start-mysql-clustermember":
        creates   => "/opt/openinfinity/$_toaspathversion/rdbms/firststart.flag",
        command   => "/etc/init.d/mysql start",
        user      => "root",
        logoutput => true,
        before    => File["/opt/openinfinity/$_toaspathversion/rdbms/firststart.flag"],
        require   => File["/opt/openinfinity/$_toaspathversion/rdbms/initiated.flag"],
    }

  }
    file { "/opt/openinfinity/$_toaspathversion/rdbms/firststart.flag":
      ensure => present,
      content => "Started",
      owner => "root",
      group => "root",
      mode => 0640,
    } 
}

class oi4portal::install (
 $liferay_package_name = undef
)  {

	package { ["java-1.8.0-openjdk", "oi4-connectorj", $liferay_package_name, "oi4-core", "oi4-tomcat", "oi4-secvault", "oi4-hazelcast"]:
		ensure => present,
	} 
#	package { ["oi4-bas"]:


	file {"/opt/openinfinity/deploy":
                ensure => directory,
                owner => 'oiuser',
                group => 'oiuser',
                mode => 0755,
        }

#	package { ["oi-theme-2.0.0-1"]:
#		ensure => present,
#		require => File["/opt/openinfinity/2.0.0/deploy"],
#	}

}

class oi4portal::config (
  $portal_multicast_address = undef,
  $portal_db_address = undef,
  $portal_db_password = undef,
  $portal_tomcat_monitor_role_password = undef,
  $portal_jvmmem = undef,
  $portal_jvmperm = undef,
  $portal_extra_jvm_opts = undef,
  $portal_extra_catalina_opts = undef,
  $oi_home = '/opt/openinfinity',
  $enable_cluster  = undef
)

{

	exec {"set-privileges":
		command => "/bin/chown -R oiuser:oiuser /opt/openinfinity/",
		require => Class["oi4portal::install"],
	}

	  file { "$oi_home/tomcat/bin/setenv.sh":
		ensure => present,
		owner => 'oiuser',
		group => 'oiuser',
		mode => 0755,
		content => template("oi4portal/setenv.sh.erb"),
		require => Class["oi4portal::install"],
		notify => Service["oi-tomcat"],
	  }

	file {"/opt/openinfinity/tomcat/webapps/ROOT/WEB-INF/classes/portal-ext.properties":
		ensure => present,
		owner => 'oiuser',
		group => 'oiuser',
		mode => 0644,
		content => template("oi4portal/portal-ext.properties.erb"),
		require => Class["oi4portal::install"],
		notify => Service["oi-tomcat"],
	}

	file {"/opt/openinfinity/tomcat/conf/catalina.properties":
                ensure => present,
                owner => 'oiuser',
                group => 'oiuser',
                mode => 0600,
                source => "puppet:///modules/oi4portal/catalina.properties",
                require => Class["oi4portal::install"],
        }

	file {"/opt/openinfinity/tomcat/conf/Catalina/localhost/ROOT.xml":
		ensure => present,
		owner => 'oiuser',
		group => 'oiuser',
		mode => 0600,
		source => "puppet:///modules/oi4portal/ROOT.xml",
		require => File["/opt/openinfinity/tomcat/conf/Catalina/localhost"],
	}

	file {"/opt/openinfinity/tomcat/conf/Catalina/localhost":
                ensure => directory,
                owner => 'oiuser',
                group => 'oiuser',
                mode => 0755,
                require => File["/opt/openinfinity/tomcat/conf/Catalina"],
    }

	file {"/opt/openinfinity/tomcat/conf/Catalina":
                ensure => directory,
                owner => 'oiuser',
                group => 'oiuser',
                mode => 0755,
                require => Class["oi4portal::install"],
    }

	# Security Vault configuration
	file {"/opt/openinfinity/tomcat/conf/securityvault.properties":
		ensure    => present,
		owner     => 'oiuser',
		group     => 'oiuser',
		mode      => 0600,
    content => template("oi4portal/securityvault.properties.erb"),
		require   => Class["oi4portal::install"],
	}

	file {"/opt/openinfinity/tomcat/conf/hazelcast.xml":
		ensure => present,
		owner => 'oiuser',
		group => 'oiuser',
		mode => 0600,
		content => template("oi4portal/hazelcast.xml.erb"),
		require => Class["oi4portal::install"],
	}
	
	file {"/opt/openinfinity/tomcat/conf/jmxremote.password":
			ensure => present,
			owner => 'oiuser',
			group => 'oiuser',
			mode => 0600,
			content => template("oi4portal/jmxremote.password.erb"),
			require => Class["oi4portal::install"],
	}

	file {"/opt/openinfinity/tomcat/conf/jmxremote.access":
			ensure => present,
			owner => 'oiuser',
			group => 'oiuser',
			mode => 0644,
			source => "puppet:///modules/oi4portal/jmxremote.access",
			require => Class["oi4portal::install"],
	}

	file {"/etc/init.d/oi-tomcat":
			ensure  => present,
			owner   => 'root',
			group   => 'root',
			mode    => 0755,
			content => template("oi4portal/oi-tomcat.erb"),
			require => Class["oi4portal::install"],
	}

	file {"/opt/openinfinity/portal-setup-wizard.properties":
		ensure    => present,
		owner     => 'oiuser',
		group     => 'oiuser',
		mode      => 0644,
    content => template("oi4portal/portal-setup-wizard.properties.erb"),
		require   => Class["oi4portal::install"],
	}
}

class oi4portal::service {
	service {"oi-tomcat":
		ensure => running,
		hasrestart => true,
		enable => true,
		require => Class["oi4portal::config"],
	}
}

class oi4portal {
	include oi4portal::install
	include oi4portal::config
	include oi4portal::service
}


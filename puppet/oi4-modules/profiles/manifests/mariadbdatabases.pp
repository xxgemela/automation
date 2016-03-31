class profiles::mariadbdatabases($nodeids=undef) {
	$portal_user_password = hiera('toas::mariadb::portal_user_password', undef)
	$oi_home = hiera('toas::oi_home', '/opt/openinfinity')
	$activiti_user_password = hiera('toas::rdbms::activiti::pw', undef)
	$activiti_httpuser_pwd = hiera('toas::rdbms::activiti::httpuser_pwd', undef)
	$activemq_user_password = hiera('toas::rdbms::activemq::pw', undef)
	$nodeids = hiera('toas::cluster::nodeids', undef)

	if $portal_user_password {
		mysql::db { 'lportal':
			user     => 'liferay',
			password => $portal_user_password,
			host     => '%',
			grant    => ['ALL'],
		}
	}

	if $activiti_user_password {

		file { "${oi_home}/activiti":
			ensure => directory,
			group  => "root",
			owner  => "root",
		}->

		file { "${oi_home}/activiti/dbschema":
			ensure => directory,
			group  => "root",
			owner  => "root",
		}->
		file { "${oi_home}/activiti/dbschema/activiti.mysql.create.sql":
			ensure => present,
			source => "puppet:///modules/profiles/activiti.mysql.create.sql",
			owner  => "root",
			group  => "root",
		} ->
		file { "${oi_home}/activiti/dbschema/activiti.mysql.add.oiuser.sql":
			ensure  => present,
			content => template("profiles/activiti.mysql.add.oiuser.sql.erb"),
			owner   => "root",
			group   => "root",
		} ->

		mysql::db { 'activiti':
			user     => 'activiti',
			password => $activiti_user_password,
			host     => '%',
			grant    => ['ALL'],
			sql      => ["${oi_home}/activiti/dbschema/activiti.mysql.create.sql", "${oi_home}/activiti/dbschema/activiti.mysql.add.oiuser.sql"]
		}
	}

	define createMQDB  ($password) {
		mysql::db { "toasamq${$name}":
			user     => 'activemq',
			password => $password,
			host     => '%',
			grant    => ['ALL'],
		}
	}

	if ($activemq_user_password && $nodeids){
		$nodeids.each |String $node_id| {
			createMQDB { $node_id:
			password => $activemq_user_password
		}
	}


}



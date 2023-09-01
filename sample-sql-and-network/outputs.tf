output "db-connection-name" {
  value       = google_sql_database_instance.default.connection_name
  description = "Cloud SQLの接続名"
}

output "db-id" {
  value       = google_sql_database_instance.default.id
  description = "Cloud SQLのインスタンスID"
}

output "db-private-ip" {
  value       = google_sql_database_instance.default.private_ip_address
  description = "Cloud SQLのPrivate IPアドレス"
}

output "db-admin-user" {
  value = {
    "username" : google_sql_user.managers["admin"].name,
    "password" : google_sql_user.managers["admin"].password,
  }

  description = "管理用SQLユーザー, このユーザーを使用してアプリケーション用のユーザーを発行してください"
}

output "db-migration-user" {
  value = {
    "username" : google_sql_user.managers["migration"].name,
    "password" : google_sql_user.managers["migration"].password,
  }

  description = "使用するかどうか未定のマイグレーション用ユーザー"
}

output "vpcconn-connection-name" {
  value       = google_vpc_access_connector.vpcaccess.id
  description = "VPCアクセスコネクターの接続名"
}

module main

@[table: 'products']
struct Product {
	id         int @[primary; sql: serial]
	user_id    int
	name       ?string @[sql_type: 'TEXT'; unique]
	created_at string  @[default: 'CURRENT_TIMESTAMP']
}

module main

import vweb
import databases
import os
import encoding.base64
import json

const port = 8082

struct App {
	vweb.Context
    middlewares map[string][]vweb.Middleware
}

pub fn (app App) before_request() {
	println('[web] before_request: ${app.req.method} ${app.req.url}')
	/*
	user_id := app.get_cookie('token') or { '0' }
	if user_id == '0' && app.req.url != '/' && app.req.url != '/status' {
		app.redirect('/')
		return
	}
*/
}

fn middleware_func(mut app vweb.Context) bool {
	println('[web] running middleware')
	user_id := app.get_cookie('token') or { '0' }
	if user_id == '0' && app.req.url == '/products'{
		app.redirect('/')
		return true
	}
	return true
}

struct Object {
	title       string
	description string
}

fn main() {
	mut db := databases.create_db_connection() or { panic(err) }

	sql db {
		create table User
		create table Product
	} or { panic('error on create table: ${err}') }

	db.close() or { panic(err) }

	mut app := &App{
		        middlewares: {
            // chaining is allowed, middleware will be evaluated in order
            '/':         [middleware_func]
        }
	}
	app.serve_static('/favicon.ico', 'src/assets/favicon.ico')
	// makes all static files available.
	app.mount_static_folder_at(os.resource_abs_path('.'), '/')
	println('Static folder path: ${os.resource_abs_path('.')}/')

	vweb.run(app, port)
}

@['/product/:count'; get]
fn (mut app App) foo(count string) vweb.Result {

	token := app.get_cookie('token') or { '' }

	if !auth_verify(token) {
		app.set_status(401, '')
		return app.text('Not valid token')
	}

	jwt_payload_stringify := base64.url_decode_str(token.split('.')[1])

	jwt_payload := json.decode(JwtPayload, jwt_payload_stringify) or {
		app.set_status(501, '')
		return app.text('jwt decode error')
	}

	user_id := jwt_payload.sub

	response := app.service_get_product_from(user_id.int(), count.int()) or {
		app.set_status(400, '')
		return app.text('${err}')
	}
	return app.json(response)

}

@['/product_all'; get]
fn (mut app App) todo_all() vweb.Result {
	token := app.get_cookie('token') or { '' }

	if !auth_verify(token) {
		app.set_status(401, '')
		return app.text('Not valid token')
	}

	jwt_payload_stringify := base64.url_decode_str(token.split('.')[1])

	jwt_payload := json.decode(JwtPayload, jwt_payload_stringify) or {
		app.set_status(501, '')
		return app.text('jwt decode error')
	}

	user_id := jwt_payload.sub

	response := app.service_get_all_products_from(user_id.int()) or {
		app.set_status(400, '')
		return app.text('${err}')
	}
	return app.json(response)
}

@['/open/:path...']
fn (mut app App) open(path string) vweb.Result {
	return app.text('open url path = "${path}"')
}

@['/status']
fn (mut app App) check_status() vweb.Result {
	user_id := app.get_cookie('token') or { '0' }
	if user_id == '0' {
		return app.text('user not logged in')
	}
	return app.text('user log in as ${user_id}')
}

@['/home']
pub fn (mut app App) page_home() vweb.Result {
	title := 'first vweb'
	repo_url := 'https://github.com/amar-jay'
	my_repos := [
		Object{
			title:       'Bitnet'
			description: 'an implementation of bitnet(1 bit LLM from Microsoft)'
		},
		Object{
			title:       'Liquid Foundation models'
			description: 'Not yet implemented but yet to'
		},
	]

	return $vweb.html()
}

@['/products'; get]
pub fn (mut app App) page_products() vweb.Result {
	token := app.get_cookie('token') or {
		app.set_status(400, '')
		return app.text('${err}')
	}

	user := get_user(token) or {
		app.set_status(400, '')
		return app.text('Failed to fetch data from the server. Error: ${err}')
	}

	username := user.username
	return $vweb.html()
}


@['/'; get]
pub fn (mut app App) index() vweb.Result {
	title := 'first vweb'


	user_id := app.get_cookie('token') or { '0' }
	if user_id != '0' && app.req.url == '/' {
		return app.redirect('/products')
	}

	return $vweb.html()
}

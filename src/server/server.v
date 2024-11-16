module main

import vweb

struct App {
	vweb.Context
}

@['/']
pub fn (mut app App) index() vweb.Result {
	return app.text('Welcome to the Vweb Server!')
}

@['/hello']
pub fn (mut app App) hello() vweb.Result {
	return app.json({
		'message': 'Hello, Vweb!'
	})
}

fn main() {
	port := 8080
	println('Vweb server running at http://localhost:${port}')
	vweb.run[App](port)
}

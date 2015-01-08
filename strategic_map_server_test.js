var request = require('request');

request.get(
	"http://localhost:9090/randomUniform",
	 function (error, response, body) {
		if(error) { console.log('error', JSON.stringify(error)); }
		console.log('response', JSON.stringify(response));
		console.log('body pre parse', JSON.stringify(body));
    }
);

rrest Documentation 
====================

#### Bug Note
Currently, the server is dropping the first '{' of the return JSON object, so it's not valid JSON. 
Also, the server generally has to be killed with Ctrl+Z rather than Ctrl+C for some reason.

#### Example Server
To start the example server, run
```bash
Rscript create_service_server.R
```

#### Example Clients

For example client in bash:

```bash
curl -X GET http://0.0.0.0:9090/randomNormal
curl -X POST http://0.0.0.0:9090/randomNormal -d '{"n" : 10}'
curl -X POST http://0.0.0.0:9090/randomUniform -d '{"n" : 20}'
```

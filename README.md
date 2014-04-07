rrest Documentation 
====================

Starting server:

```r
# Define some sample functions
randomUniform <- function(p) {
    p <- lapply(p, as.numeric)
    runif(p$n)
}

randomNormal <- function(p) {
    p <- lapply(p, as.numeric)
    rnorm(p$n)
}

# Defining 'function environment' to keep user from executing arbitrary
# functions
fun_env <- new.env()
assign("randomUniform", randomUniform, env = fun_env)
assign("randomNormal", randomNormal, env = fun_env)

runServer(host = "0.0.0.0", port = 9090, app = list(call = restServer(fun_env)))
```



Example R Client:


```r
require(RCurl)
require(RJSONIO)

body <- list(fun = "randomNormal", params = list(n = 100))

curlPerform(url = "http://localhost:9090", postfields = toJSON(body))
```


or the same thing in bash:
```bash
curl -X POST http://localhost:9090 -d '{"fun": "randomNormal", "params" : {"n" : 100}}'
```




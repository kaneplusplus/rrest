# RRest Server


require(httpuv)
require(RJSONIO)

restServer <- function(fun_env) {
	
  function(env){
    method <- env[['REQUEST_METHOD']]
    resp   <- '{"null_response" : undefined}'	
    if(method == 'POST') {	
	  postfields <- rawToChar(env[['rook.input']]$read())
	  postfields <- fromJSON(postfields)
	  if(length(postfields) == 2){
	    fun <- fun_env[[postfields[['fun']]]]
	    if(!is.null(fun)){
	      params <- postfields[['params']]
	      resp   <- toJSON(fun(params))
	    } else {
	      print('unsupported function!')
	    }
	  }
	} else {
	  print('unsupported request!')
	}
		
	list(
	  status  = 200L,
	  headers = list('Content-Type' = 'JSON'),
	  body    = resp
	)
  }  
}











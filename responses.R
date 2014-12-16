success <- function(resp) {
	list(
	  status  = 200L,
	  headers = list('Content-Type' = 'JSON'),
	  body    = resp
	)	
}

method_not_found <- function() {
	list(
	  status  = 405,
	  headers = list('Content-Type' = 'text'),
	  body    = "Method not allowed"
	)		
}

throw_error <- function() {
	list(
	  status  = 500,
	  headers = list('Content-Type' = 'text'),
	  body    = "Internal server error occured"
	)
}
wrk.method = "GET"
wrk.body   = [[{ "query":"query me {\n id\n }\n}\n"}]]
wrk.headers["x-token"]="ENTER TOKEN HERE"
wrk.headers["Content-Type"] = "application/json"
wrk.headers["Accept"] = "application/json"

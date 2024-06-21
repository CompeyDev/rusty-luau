<!-- markdownlint-disable MD023 -->
<!-- markdownlint-disable MD033 -->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## `0.2.0` - June 21st, 2024

This release includes various changes to API interfaces, documentation, and includes new 
implementations.

- Fixed inconsistencies `Option` & `Result` implementations
- Implemented `Future`, a pollable asynchronous idiom, alternative to promises

  ```luau
	local net = require("@lune/net")

	local fut: Future<Result<string, string>> = Future.try(function(url)
		local resp = net.request({
			url = url,
			method = "GET",
		})

		assert(resp.ok)

		return resp.body
	end, { "https://jsonplaceholder.typicode.com/posts/1" })

	local resp: Result<string, string> = fut:await()
	print(net.jsonDecode(resp:unwrap()))
	```

- Added documentation for all available implementations
- Included CI action
- Added examples for `Result`
- Removed incomplete `Iter` implementation

## `0.1.0` - April 2nd, 2024

The very first release of rusty-luau.

- Initial `Option` & `Result` implementations

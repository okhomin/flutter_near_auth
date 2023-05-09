<!-- USAGE EXAMPLES -->

## Usage

> You need to replace `nearEndpoint` and `contractID` with the [`NEAR RPC provider`](https://docs.near.org/api/rpc/providers) you want to use and with the `contract id` of your application in the [main.go](./backend/cmd/main.go#L15-L18) file.
```go
package main

const (
	nearEndpoint = "https://rpc.testnet.near.org"
	contractID   = "auth.coatyworld1.testnet"
)
```

### Running Backend
[`main.go`](./cmd/main.go) contains the backend logic that is responsible for the validation process of the data received from the Flutter client.
Also, it contains the logic of serving the [`HTML file`](./index.html) that is used for redirection to the NEAR wallet.  
The server will be available at `localhost:8080` by default. If you want to change the port, you need to change the [`main.go`](./cmd/main.go#L108) file.

```sh
go run cmd/main.go
```


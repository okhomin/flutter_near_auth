package near

import (
	"context"
	"errors"
	"github.com/ybbus/jsonrpc/v3"
	"time"
)

// Client contains the json RPC client
type Client struct {
	rpcClient jsonrpc.RPCClient
}

// NewClient create a new json RPC client for the given endpoint
func NewClient(endpoint string) *Client {
	return &Client{
		rpcClient: jsonrpc.NewClient(endpoint),
	}
}

// ViewAccessKey calls the view_access_key RPC method
// https://docs.near.org/api/rpc/access-keys#view-access-key
func (c *Client) ViewAccessKey(ctx context.Context, accountID, publicKey string) (ViewAccessKeyResponse, error) {
	const (
		requestType = "view_access_key"
		finality    = "final"
		method      = "query"
	)

	request := ViewAccessKeyRequest{
		RequestType: requestType,
		Finality:    finality,
		AccountID:   accountID,
		PublicKey:   publicKey,
	}
	var response ViewAccessKeyResponse

	// wait for three seconds before calling the RPC method
	// final state of the blockchain is not guaranteed if the RPC method is called immediately after the transaction is submitted
	// final state of the blockchain is guaranteed after confirmation depth of 2 blocks
	// average time for producing a block is ~1.1 seconds. So, waiting for 3 seconds is sufficient. https://explorer.near.org/
	time.Sleep(3 * time.Second)

	if err := c.rpcClient.CallFor(ctx, &response, method, &request); err != nil {
		// return empty response and error if there is an error calling the RPC method
		return ViewAccessKeyResponse{}, err
	}
	if response.Error != "" {
		// return empty response and error if there is an error in the RPC response
		return ViewAccessKeyResponse{}, errors.New(response.Error)
	}

	return response, nil
}

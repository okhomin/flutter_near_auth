package main

import (
	"crypto/ed25519"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"github.com/btcsuite/btcutil/base58"
	"github.com/okhomin/flutter_near_auth/backend/near"
	"math/rand"
	"net/http"
)

const (
	nearEndpoint = "https://rpc.testnet.near.org"
	contractID   = "auth.coatyworld1.testnet"
)

var (
	// nearClient is the json rpc client for the NEAR RPC endpoint
	nearClient = near.NewClient(nearEndpoint)
)

type AuthRequest struct {
	AccountID string `json:"account_id"`
	Signature string `json:"signature"`
	PublicKey string `json:"public_key"`
}

type AuthResponse struct {
	Token string `json:"token"`
}

func VerifySignature(accountID, publicKey, signature string) error {
	// decode base64 signature
	decodedSignature, err := base64.StdEncoding.DecodeString(signature)
	if err != nil {
		return err
	}

	// remove the ed25519: prefix from the public key and decode base58
	decodedPublicKey := base58.Decode(publicKey[8:])
	if err != nil {
		return err
	}

	// verify the signature with the decoded public key and account id
	if ok := ed25519.Verify(decodedPublicKey, []byte(accountID), decodedSignature); !ok {
		return errors.New("invalid signature")
	}

	return nil
}

func NEARAuthentication(w http.ResponseWriter, req *http.Request) {
	var authRequest AuthRequest
	if err := json.NewDecoder(req.Body).Decode(&authRequest); err != nil {
		// return error if there is an error decoding the request body
		http.Error(w, "invalid request", http.StatusBadRequest)
		return
	}

	// verify the signature
	if err := VerifySignature(authRequest.AccountID, authRequest.PublicKey, authRequest.Signature); err != nil {
		// return error if there is an error verifying the signature
		http.Error(w, "invalid signature", http.StatusUnauthorized)
		return
	}

	// check if the access key is present on the account
	viewAccessKeyResponse, err := nearClient.ViewAccessKey(req.Context(), authRequest.AccountID, authRequest.PublicKey)
	if err != nil {
		// return error if there is an error verifying the access key
		http.Error(w, err.Error(), http.StatusUnauthorized)
		return
	}

	// check if the receiver id from the access key matches the contract id
	if viewAccessKeyResponse.Permission.FunctionCall.ReceiverID != contractID {
		// return error if the receiver id does not match the contract id
		http.Error(w, "invalid contract id", http.StatusUnauthorized)
		return
	}

	// on this point, the user is authenticated
	// account id is the user id and can be used to identify the user for the future requests

	// generate a success response
	authResponse := AuthResponse{
		Token: fmt.Sprintf("%v", rand.Intn(99999)), // token can be anything that can be used to identify the user for the future requests.
	}
	if err := json.NewEncoder(w).Encode(authResponse); err != nil {
		// return error if there is an error encoding the response
		http.Error(w, "error encoding response", http.StatusInternalServerError)
		return
	}
}

func main() {
	// handle NEAR authentication requests on the /auth endpoint
	http.HandleFunc("/auth", NEARAuthentication)

	// serve the redirector on the /near endpoint
	http.Handle("/near/", http.StripPrefix("/near/", http.FileServer(http.Dir("./"))))

	// start the server on port 8080
	http.ListenAndServe(":8080", nil)
}

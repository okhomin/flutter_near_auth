package near

type ViewAccessKeyRequest struct {
	RequestType string `json:"request_type"`
	Finality    string `json:"finality,omitempty"`
	BlockID     string `json:"block_id,omitempty"`
	AccountID   string `json:"account_id"`
	PublicKey   string `json:"public_key"`
}

type FunctionCall struct {
	ReceiverID string `json:"receiver_id"`
}

type Permission struct {
	FunctionCall FunctionCall `json:"FunctionCall"`
}

type ViewAccessKeyResponse struct {
	Nonce       uint64     `json:"nonce"`
	BlockHeight uint64     `json:"block_height"`
	BlockHash   string     `json:"block_hash"`
	Permission  Permission `json:"permission"`
	Error       string     `json:"error"`
}

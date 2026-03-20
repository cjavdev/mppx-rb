# mppx

Ruby SDK for the [Machine Payments Protocol](https://paymentauth.org) (MPP). Implements the Payment HTTP Authentication Scheme (HTTP 402) for payment-gated APIs.

## Installation

Add to your Gemfile:

```ruby
gem "mppx"
```

Then run:

```sh
bundle install
```

Or install directly:

```sh
gem install mppx
```

## Quick Start

### Server: Protect an endpoint with payment gating

```ruby
require "mppx"

# Define a payment method with name, intent, and schema
method = Mppx::Method.from(
  name: "tempo",
  intent: "charge",
  schema: {
    request: ->(r) { r },
    credential: { payload: ->(p) { p } }
  }
)

# Configure the server method with a verification callback
server_method = Mppx::Method.to_server(method,
  verify: ->(credential:, request:) {
    # Verify the payment and return receipt data
    Mppx::Receipt.from(
      method: "tempo",
      reference: "tx_123",
      status: "success",
      timestamp: Time.now.utc.iso8601
    )
  }
)

# Create a handler
handler = Mppx::Server::Handler.create(
  methods: [server_method],
  secret_key: ENV["MPP_SECRET_KEY"],
  realm: "My API"
)
```

### Server: Rack middleware

```ruby
# In your Rack app or Rails config
use Mppx::Server::Middleware,
  handler: handler,
  method_key: "charge",
  options: { amount: "0.01", currency: "USD" }
```

### Client: Build and send a credential

```ruby
# Parse the 402 challenge from response headers
challenge = Mppx::Challenge.from_headers(response_headers)

# Create a credential with payment proof
credential = Mppx::Credential.from(
  challenge: challenge,
  payload: { transaction_hash: "0xabc..." }
)

# Serialize for the Authorization header
auth_header = Mppx::Credential.serialize(credential)
# => "Payment eyJjaGFsbGVuZ2U..."
```

### Parse a receipt

```ruby
receipt = Mppx::Receipt.from_response(response_headers)
# => { method: "tempo", reference: "tx_123", status: "success", timestamp: "..." }
```

## Modules

| Module | Purpose |
|--------|---------|
| `Mppx::Challenge` | Create, serialize, deserialize, and verify 402 challenges |
| `Mppx::Credential` | Build and parse `Authorization: Payment ...` credentials |
| `Mppx::Receipt` | Create and parse `Payment-Receipt` headers |
| `Mppx::PaymentRequest` | Serialize/deserialize payment request objects |
| `Mppx::Method` | Define payment methods with schemas for client and server use |
| `Mppx::Store` | Pluggable key-value stores (in-memory, Redis) |
| `Mppx::Server::Handler` | Server-side handler that validates credentials and issues challenges |
| `Mppx::Server::Transport` | HTTP transport layer for challenge/receipt responses |
| `Mppx::Server::Middleware` | Rack middleware for payment gating |
| `Mppx::BodyDigest` | SHA-256 body digest computation and verification |
| `Mppx::Errors` | Structured error types following RFC 9457 Problem Details |

## Configuration

The handler reads these environment variables:

- `MPP_SECRET_KEY` - HMAC secret for signing challenges (required unless passed directly)
- `MPP_REALM` - Default realm for challenges (optional)

## Development

```sh
bundle install
bundle exec rake spec
```

## Requirements

- Ruby >= 3.1

## License

MIT

Connecting to Binance WebSocket API
To start using the Binance WebSocket API, a client must establish a connection to one of Binance’s WebSocket endpoints. The base WebSocket endpoint for the API is:


wss://ws-api.binance.com/ws-api/v3
Binance also provides a testnet environment for users to test WebSocket functionality without interacting with the live market. The testnet WebSocket API can be accessed using the following endpoint:


wss://ws-api.testnet.binance.vision/ws-api/v3
Establishing a WebSocket Connection
To interact with the Binance WebSocket API, a connection must be established first. WebSockets provide a persistent, full-duplex communication channel, allowing real-time data exchange.

When implementing WebSocket connections, it is important to:

Handle reconnections in case of network issues.

Manage timeouts and errors, as interruptions can occur due to server restarts, network instability, or API rate limits.

Monitor the connection state and respond appropriately to connection events, such as successful connections, disconnections, errors, and incoming messages.

Example: Establishing a Connection

Code Snippet

Python
import threading
import websocket

client = websocket.WebSocketApp(
    "wss://ws-api.binance.com/ws-api/v3",
    on_open=lambda ws: print("Connection opened"),
    on_close=lambda ws, code, msg: print("Connection closed"),
    on_error=lambda ws, error: print(f"Error: {error}"),
    on_message=lambda ws, message: print(f"Message received: {message}")
)

wst = threading.Thread(target=client.run_forever, daemon=True)
wst.start()
Sending a Basic Request
Once connected, users can request specific data, such as exchange information, which includes available trading pairs, rate limits, and API specifications.

Example: Fetching Exchange Information

Code Snippet

Python
import json
import uuid

request = {
    "id": str(uuid.uuid4()),
    "method": "exchangeInfo",
    "params": {
      "symbol": "BNBUSDT"
    }
}
client.send(json.dumps(request))
Understanding exchange information is critical for planning trading strategies and ensuring compliance with Binance’s rate limits and available markets.

Correlating Request with Response
Since WebSocket responses are asynchronous, multiple responses can arrive in any order. Each response includes the same ID value as the corresponding request, allowing clients to correlate them.

Tracking responses efficiently is crucial in high-frequency trading applications where multiple requests may be sent in parallel.

Best Practices for Managing Responses:

Use a structured approach to track sent request IDs and match them with corresponding responses, ensuring efficient request-response correlation.

Use timeouts to handle delayed responses and prevent hanging requests.

Log every request and response for debugging purposes.

Implement error-handling logic to detect failed requests and retry them if necessary.

Example: Fetching Exchange Information With Custom ID

Code Snippet

Python
request = {
    "id": "your-tracked-id",
    "method": "exchangeInfo",
    "params": {
      "symbol": "BNBUSDT"
    }
}
client.send(json.dumps(request))
The response will include the same ID, helping to track the request.

Session Logon, Logout, and Status
For user-specific operations, such as placing trades or accessing account details, authentication is required. Binance WebSocket API allows a session logon to avoid authentication for every request.

Session Logon Benefits:

Reduces redundant authentication for every API request.

Ensures a secure, active session for a given API key.

Simplifies user data stream management by ensuring an authenticated connection remains open.

Maintaining an authenticated session improves efficiency, but users must be mindful that the authenticated session is only valid for that specific session and API key.

Session Logon
Logging into a session allows users to avoid including authentication credentials in every authenticated request. For WebSocket session logon, only Ed25519 keys are supported—HMAC and RSA authentication methods are not available for this feature.

Ed25519 is a modern cryptographic signature algorithm that provides high security, compact key sizes, and fast verification, making it well-suited for real-time WebSocket authentication.

Example: Authenticating a Session

Code Snippet

Python
import time
from urllib.parse import urlencode
from base64 import b64encode
from Crypto.PublicKey import ECC
from Crypto.Signature import eddsa

api_key = "your_api_key"
private_key = "your_private_key"
private_key_passphrase = "your_private_key_passphrase"
timestamp = int(time.time() * 1000)

# Create Ed25519 signature
payload = {"apiKey": api_key, "timestamp": timestamp}
signature_payload = urlencode(payload, True)
private_key = ECC.import_key(private_key, passphrase=private_key_passphrase)
signer = eddsa.new(private_key, "rfc8032")
signature = b64encode(signer.sign(signature_payload.encode("utf-8"))).decode()

request = {
    "id": str(uuid.uuid4()),
    "method": "session.logon",
    "params": {
        "apiKey": api_key,
        "timestamp": timestamp,
        "signature": signature
    }
}
client.send(json.dumps(request))
NOTE: Before using requests like user data streams subscription, a session logon request must be sent.

Session Status
After logging in, users can check the current session status to verify authentication and connection status.

Example: Checking Session Status

Code Snippet

Python
request = {
    "id": str(uuid.uuid4()),
    "method": "session.status"
}

client.send(json.dumps(request))
NOTE: This request helps confirm whether the session is active and authenticated before sending further API requests.

Session Logout
To securely close the authenticated session, users can use the session.logout method. This ensures that the API key is no longer associated with the WebSocket connection.

Example: Logging Out of a Session

Code Snippet

Python
request = {
    "id": str(uuid.uuid4()),
    "method": "session.logout"
}

client.send(json.dumps(request))
NOTE: Logging out will terminate authentication for the current WebSocket session. To send further authenticated requests, users must log in again using session.logon.

Proper handling of session management is critical to maintaining connection stability and preventing disruptions.

Advantages and Disadvantages 
Data the docs confirm
Prediction wallet events (Binance SApi WSS)

14 event types are pushed to individual users in real time.
They cover trading (market and limit), reward claims, fund transfers and market resolution.
I couldn't confirm the per-event field names.
Alpha WebSocket Market Data

Base URL: wss://nbstream.binance.com/w3w/wsa/stream
You can send SUBSCRIBE, UNSUBSCRIBE and list-subscriptions requests.
Available streams:
@ticker, !ticker@arr
@miniTicker, !miniTicker@arr
@bookTicker, !bookTicker
@aggTrade, @trade
@kline_<interval>
@depth (UI orders only)
@fulldepth@<interval> (UI and API orders)
came@allTokens@ticker24
came@contractAddress@chainId@kline_<interval>
Depth events use the update IDs U, u and pu.
I couldn't confirm the other per-stream response fields.
Feature ideas (my suggestions, not from the docs, no payments)
Live watchlist with 24h price change, using the ticker streams.
Candlestick charts with an interval selector, using kline.
Order book and depth view.
Recent trades feed.
Price alerts based on stream data.
Market and event notifications, such as Prediction market resolution.
A Prediction activity timeline for trades and claims.
Reconnect and connection-status indicator.
Offline cache of the last known data.
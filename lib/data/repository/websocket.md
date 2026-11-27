 WebSocket Streams documentation
## General WebSocket Streams Information

* **Base Endpoints:** `wss://stream.binance.com:9443` or `wss://stream.binance.com:443`.


* **Stream Types:**
* Raw streams: `/ws/<streamName>`.


* Combined streams: `/stream?streams=<streamName1>/<streamName2>` formatted as `{"stream":"<streamName>","data":<rawPayload>}`.


* **Connection Lifecycle:** Connections expire after 24 hours. Servers send a `ping frame` every 20 seconds, and clients must reply with a `pong frame` (recommended empty payload) within 1 minute or face disconnection.


* **Market Data Only:** `wss://data-stream.binance.vision` supports market data messages exclusively (no user data streams).


* **Timestamps:** Provided in milliseconds by default, or microseconds by adding `timeUnit=MICROSECOND` (or `microsecond`) to the URL.



---

## WebSocket Limits

* **Message Rate:** Maximum of 5 incoming messages (PING, FRAME, JSON control) per second per connection.


* **Streams per Connection:** Maximum of 1024 streams.


* **IP Limit:** Maximum of 300 connection attempts every 5 minutes per IP.



---

## Server Shutdown

When a `serverShutdown` event occurs, establish a new connection immediately to prevent interruption.

* Raw stream payload:


```javascript
{
  "e": "serverShutdown", // Event type
  "E": 1770123456789,    // Event time
  "T": 1770124000000     // Upcoming shutdown time
}

```


* Combined stream payload:


```javascript
{
  "stream": "!serverShutdown",
  "data": {
    "e": "serverShutdown", // Event type
    "E": 1770123456789,    // Event time
    "T": 1770124000000     // Upcoming shutdown time
  }
}

```



---

## Live Subscribing & Management

Clients can send JSON commands (`SUBSCRIBE`, `UNSUBSCRIBE`, `LIST_SUBSCRIPTIONS`, `SET_PROPERTY`, `GET_PROPERTY`) using an `id` (64-bit integer, string up to 36 chars, or `null`). A `result: null` indicates success for non-query requests.

* Subscribe:


```javascript
{
    "method": "SUBSCRIBE",
    "params": ["btcusdt@aggTrade", "btcusdt@depth"],
    "id": 1
}

```


Response:


```javascript
{
    "result": null,
    "id": 1
}

```


* Unsubscribe:


```javascript
{
    "method": "UNSUBSCRIBE",
    "params": ["btcusdt@depth"],
    "id": 312
}

```


Response:


```javascript
{
    "result": null,
    "id": 312
}

```


* Listing Subscriptions:


```javascript
{
    "method": "LIST_SUBSCRIPTIONS",
    "id": 3
}

```


Response:


```javascript
{
    "result": ["btcusdt@aggTrade"],
    "id": 3
}

```


* Setting Properties:


```javascript
{
    "method": "SET_PROPERTY",
    "params": ["combined", true],
    "id": 5
}

```


Response:


```javascript
{
    "result": null,
    "id": 5
}

```


* Retrieving Properties:


```javascript
{
    "method": "GET_PROPERTY",
    "params": ["combined"],
    "id": 2
}

```


Response:


```javascript
{
    "result": true, // Indicates that combined is set to true.
    "id": 2
}

```



---

## Managing a Local Order Book Correctly

1. Connect to `wss://[stream.binance.com:9443/ws/bnbbtc@depth](https://stream.binance.com:9443/ws/bnbbtc@depth)`.


2. Buffer incoming stream events and note the `U` value of the first event.


3. Fetch a depth snapshot from `[https://api.binance.com/api/v3/depth?symbol=BNBBTC&limit=5000](https://api.binance.com/api/v3/depth?symbol=BNBBTC&limit=5000)`.


4. If `lastUpdateId` from the snapshot is `< U`, repeat step 3.


5. Discard buffered events where `u <= lastUpdateId`.


6. Set the local order book to the snapshot (`lastUpdateId`).


7. Apply updates: ignore events where `u < orderBookId`, restart if `U > orderBookId + 1`, adjust bid/ask quantities, and update order book ID to `u`.
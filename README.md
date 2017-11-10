# Simple blockchain (ruby)

Ruby version: [Building a Blockchain](https://github.com/dvf/blockchain)

## Development

* Recommend Ruby 2.3

* Install required gem

```
bundle install
```

* Start server (sinatra)

```
bundle exec ruby server.rb

# with port
PORT=7890 bundle exec ruby server.rb
```

* Show blockchain

```
curl http://localhost:4567/chain
```

* Add new transaction

```
curl -X POST -H "Content-Type: application/json" -d '{
 "sender": "d4ee26eee15148ee92c6cd394edd974e",
 "recipient": "someone-other-address",
 "amount": 5
}' "http://localhost:4567/transactions/new"
```

* Mining

```
curl http://localhost:4567/mine
```

* Add new node

```
curl -X POST -H "Content-Type: application/json" -d '{
    "nodes": ["http://localhost:7890"]
}' "http://localhost:4567/nodes/register"
```

* Resolve blockchain with other nodes

```
curl "http://localhost:4567/nodes/resolve"

{"message":"Replaced chain","new_chain":[{"index":1,"timestamp":1510299792.313664,"transactions":[],"proof":100,"previous_hash":1},{"index":2,"timestamp":1510299819.23403,"transactions":[{"sender":"d4ee26eee15148ee92c6cd394edd974e","recipient":"06f42842c8a32d4bdf912ab2b110ecbf","amount":1},{"sender":"0","recipient":"eeb4544b2f5441d0a929c0b9827990e0","amount":1}],"proof":35293,"previous_hash":"a0ff32762eaa043d1fb01561c27f1e7dd5b29361446f75c2a8cda56d1645eb84"}]}
```

require 'sinatra'
require 'sinatra/json'
require 'securerandom'
require 'json'

require './blockchain'

set :port, ENV['PORT'] || '4567'

# Generate a globally unique address for this node
node_identifier = SecureRandom.uuid.gsub('-', '')

# Instantiate the Blockchain
blockchain = Blockchain.new

# Show all blockchain
get '/chain' do
  response = {
    'chain' => blockchain.chain,
    'length' => blockchain.chain.length
  }
  json response, charset: 'utf-8'
end

# Create new transaction
post '/transactions/new', provides: :json do
  params = JSON.parse(request.body.read)

  # Check that the required fields are in the POST'ed data
  required = %w(sender recipient amount)
  unless required.all? { |key| params.keys.include?(key) }
    status 400
    return 'Missing values'
  end

  # Create a new Transaction
  index = blockchain.new_transaction(
    sender: params['sender'], recipient: params['recipient'], amount: params['amount']
  )

  response = { message: "Transaction will be added to Block #{index}" }
  status 201
  json response, charset: 'utf-8'
end

# mining
get '/mine' do
  # We run the proof of work algorithm to get the next proof...
  last_block = blockchain.last_block
  last_proof = last_block['proof']
  proof = blockchain.proof_of_work(last_proof)

  # We must receive a reward for finding the proof.
  # The sender is "0" to signify that this node has mined a new coin.
  blockchain.new_transaction(
    sender: '0',
    recipient: node_identifier,
    amount: 1
  )

  # Forge the new Block by adding it to the chain
  block = blockchain.new_block(proof: proof)

  response = {
    'message' => 'New Block Forged',
    'index' => block['index'],
    'transactions' => block['transactions'],
    'proof' => block['proof'],
    'previous_hash' => block['previous_hash']
  }

  status 200
  json response
end

# Add nodes
post '/nodes/register', provides: :json do
  params = JSON.parse(request.body.read)

  nodes = params['nodes']
  unless nodes
    status 400
    return 'Missing values'
  end

  # ノードを追加する
  nodes.each do |node|
    blockchain.register_node(node)
  end

  response = {
    'message' => 'New nodes have been added',
    'total_nodes' => blockchain.nodes.length
  }
  status 201
  json response
end

get '/nodes/resolve' do
  if blockchain.resolve_conflicts
    response = {
      'message' => 'Our chain was replaced',
      'new_chain' => blockchain.chain
    }
  else
    response = {
      'message' => 'Our chain is authoritative',
      'chain' => blockchain.chain
    }
  end
  status 200
  json response
end

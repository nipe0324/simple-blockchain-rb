require 'json'
require 'digest'
require 'net/http'
require 'set'
# require 'pry-byebug'

class Blockchain
  attr_reader :chain, :current_transactions, :nodes

  def initialize
    @chain = []
    @current_transactions = []
    @nodes = Set.new

    # Create the genesis block
    self.new_block(previous_hash: 1, proof: 100)
  end

  # Create a new Block in the Blockchain
  def new_block(proof:, previous_hash: nil)
    block = {
      'index' => chain.length + 1,
      'timestamp' => Time.now.to_f,
      'transactions' => current_transactions,
      'proof' => proof,
      'previous_hash' => previous_hash || hash(block: last_block)
    }

    # Reset the current list of transactions
    @current_transactions = []
    chain.push(block)
    block
  end

  # Creates a new transaction to go into the next mined Block
  def new_transaction(sender:, recipient:, amount:)
    current_transactions.push(
      'sender' => sender,
      'recipient' => recipient,
      'amount' => amount
    )
    last_block['index'] + 1
  end

  def last_block
    chain[-1]
  end

  # Simple Proof of Work Algorithm:
  # - Find a number p' such that hash(pp') contains leading 4 zeroes, where p is the previous p'
  # - p is the previous proof, and p' is the new proof
  def proof_of_work(last_proof)
    proof = 0
    while !valid_proof?(last_proof: last_proof, proof: proof) do
      proof += 1
    end
    proof
  end

  # This is our consensus algorithm, it resolves conflicts
  # by replacing our chain with the longest one in the network.
  # True if our chain was replaced, False if not
  def resolve_conflicts
    neighbors = nodes
    new_chain = nil
    max_length = chain.length

    neighbors.each do |node|
      response = get_request(URI.parse("http://#{node}/chain"))
      if response.code == '200'
        response_body = JSON.parse(response.body)
        length = response_body['length']
        chain = response_body['chain']

        # Check if the length is longer and the chain is valid
        if length > max_length && valid_chain?(chain)
          max_length = length
          new_chain = chain
        end
      end
    end

    # Replace our chain if we discovered a new, valid chain longer than ours
    if new_chain
      @chain = new_chain
      true
    else
      false
    end
  end

  # Add a new node to the list of nodes
  # address ex: http://192.168.0.5:5000
  def register_node(address)
    parsed_url = URI.parse(address)
    nodes.add("#{parsed_url.host}:#{parsed_url.port}")
  end

  private

  # Creates a SHA-256 hash of a Block
  def hash(block:)
    block_string = JSON.dump(block)
    Digest::SHA256.hexdigest(block_string)
  end

  # Validates the Proof
  def valid_proof?(last_proof:, proof:)
    guess = "#{last_proof}#{proof}"
    guess_hash = Digest::SHA256.hexdigest(guess)
    guess_hash[0..3] == '0000'
  end

  # Determine if a given blockchain is valid
  def valid_chain?(chain)
    last_block = chain[0]
    current_index = 1

    while current_index < chain.length do
      block = chain[current_index]
      puts last_block
      puts block
      puts "\n------------------\n"

      # validate hash of block
      return false if block['previous_hash'] != hash(block: last_block)

      # validate proof of work
      return false unless valid_proof?(last_proof: last_block['proof'], proof: block['proof'])

      last_block = block
      current_index += 1
    end
    true
  end

  def get_request(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    http.request(request)
  end
end

defmodule Gold do
  use GenServer

  require Logger

  alias Gold.Config
  alias Gold.Transaction
  alias Gold.Block

  @satoshi_exponent Application.get_env(:gold, :satoshi_exponent)

  ##
  # Client-side
  ##
  @doc """
  Starts GenServer link with Gold server.
  """
  def start_link(config), do: GenServer.start_link(__MODULE__, config)
  def start_link(config, name), do: GenServer.start_link(__MODULE__, config, name: name)

  @doc """
  Returns the addresses for an account.
  """
  def getaddressesbyaccount(pid, account) do
    GenServer.call(pid, {:getaddressesbyaccount, [account]})
  end

  @doc """
  Returns the addresses for an account, raising an exception on failure.
  """
  def getaddressesbyaccount!(pid, account) do
    {:ok, addresses} = getaddressesbyaccount(pid, account)
    addresses
  end

  @doc """
  Returns server's total available balance.
  """
  def getbalance(pid) do
    case GenServer.call(pid, :getbalance) do
      {:ok, balance} -> 
        {:ok, btc_to_decimal(balance)}
      otherwise -> 
        otherwise
    end        
  end

  @doc """
  Returns server's total available balance, raising an exception on failure.
  """
  def getbalance!(pid) do
    {:ok, balance} = getbalance(pid)
    balance
  end

  @doc """
  Returns the raw block with hash.
  """
  def getblock(pid, hash) do
    case GenServer.call(pid, {:getblock, [hash]}) do
      {:ok, block} ->
        {:ok, Block.from_json block}
      otherwise ->
        otherwise
    end
  end

  @doc """
  Returns the raw block with hash, raising an exception on failure.
  """
  def getblock!(pid, hash) do
    {:ok, block} = getblock(pid, hash)
    block
  end

  @doc """
  Returns the current number of blocks.
  """
  def getblockcount(pid), do: GenServer.call(pid, :getblockcount)

  @doc """
  Returns the current number of blocks, raising an exception on failure.
  """
  def getblockcount!(pid) do
    {:ok, count} = getblockcount(pid)
    count
  end

  @doc """
  Returns the hash for block at height index.
  """
  def getblockhash(pid, index), do: GenServer.call(pid, {:getblockhash, [index]})

  @doc """
  Returns the hash for block at height index, raising an exception on failure.
  """
  def getblockhash!(pid, index) do
    {:ok, hash} = getblockhash(pid, index)
    hash
  end

  @doc """
  Returns a new bitcoin address for receiving payments.
  """
  def getnewaddress(pid), do: getnewaddress(pid, "")

  @doc """
  Returns a new bitcoin address for receiving payments, raising an exception on failure.
  """
  def getnewaddress!(pid), do: getnewaddress!(pid, "")

  @doc """
  Returns a new bitcoin address for receiving payments.
  """
  def getnewaddress(pid, account), do: GenServer.call(pid, {:getnewaddress, [account]})

  @doc """
  Returns a new bitcoin address for receiving payments, raising an exception on failure.
  """
  def getnewaddress!(pid, account) do
    {:ok, address} = getnewaddress(pid, account)
    address
  end

  @doc """
  Returns the account associated with the given address.
  """
  def getaccount(pid, address), do: GenServer.call(pid, {:getaccount, [address]})

  @doc """
  Returns the account associated with the given address, raising an exception on failure.
  """
  def getaccount!(pid, address) do
    {:ok, account} = getaccount(pid, address)
    account
  end

  @doc """
  Returns the accounts and their balances.
  """
  def listaccounts(pid) do
    GenServer.call(pid, :listaccounts)
  end

  @doc """
  Returns the accounts and their balances, raising an exception on failure.
  """
  def listaccounts!(pid) do
    {:ok, accounts} = listaccounts(pid)
    accounts
  end

  @doc """
  Returns most recent transactions in wallet.
  """
  def listtransactions(pid), do: listtransactions(pid, "*")

  @doc """
  Returns most recent transactions in wallet, raising an exception on failure.
  """
  def listtransactions!(pid), do: listtransactions!(pid, "*")

  @doc """
  Returns most recent transactions in wallet.
  """
  def listtransactions(pid, account), do: listtransactions(pid, account, 10)

  @doc """
  Returns most recent transactions in wallet, raising an exception on failure.
  """
  def listtransactions!(pid, account), do: listtransactions!(pid, account, 10)

  @doc """
  Returns most recent transactions in wallet.
  """
  def listtransactions(pid, account, limit), do: listtransactions(pid, account, limit, 0)

  @doc """
  Returns most recent transactions in wallet, raising an exception on failure.
  """
  def listtransactions!(pid, account, limit), do: listtransactions!(pid, account, limit, 0)

  @doc """
  Returns most recent transactions in wallet.
  """
  def listtransactions(pid, account, limit, offset) do
    case GenServer.call(pid, {:listtransactions, [account, limit, offset]}) do
      {:ok, transactions} ->
        {:ok, Enum.map(transactions, &Transaction.from_json/1)}
      otherwise ->
        otherwise
    end        
  end

  @doc """
  Returns most recent transactions in wallet, raising an exception on failure.
  """
  def listtransactions!(pid, account, limit, offset) do
    {:ok, transactions} = listtransactions(pid, account, limit, offset)
    transactions
  end

  @doc """
  Get detailed information about in-wallet transaction.
  """
  def gettransaction(pid, txid) do
    case GenServer.call(pid, {:gettransaction, [txid]}) do
      {:ok, transaction} ->
        {:ok, Transaction.from_json transaction}
      otherwise ->
        otherwise
    end
  end

  @doc """
  Get detailed information about in-wallet transaction, raising an exception on
  failure.
  """
  def gettransaction!(pid, txid) do
    {:ok, tx} = gettransaction(pid, txid)
    tx
  end

  @doc """
  Get raw transaction by id.
  """
  def getrawtransaction(pid, txid) do
    GenServer.call(pid, {:getrawtransaction, [txid]})
  end

  @doc """
  Get raw transaction by id, raising an exception on
  failure.
  """
  def getrawtransaction!(pid, txid) do
    {:ok, tx} = getrawtransaction(pid, txid)
    tx
  end

  @doc """
  Send an amount to a given address.
  """
  def sendtoaddress(pid, address, %Decimal{} = amount) do
    GenServer.call(pid, {:sendtoaddress, [address, amount]})
  end

  @doc """
  Send an amount to a given address, raising an exception on failure.
  """
  def sendtoaddress!(pid, address, %Decimal{} = amount) do
    {:ok, txid} = sendtoaddress(pid, address, amount)
    txid
  end

  @doc """
  Add an address or pubkey script to the wallet without the associated private key.
  """
  def importaddress(pid, address), do: importaddress(pid, address, "")

  @doc """
  Add an address or pubkey script to the wallet without the associated private key,
  raising an exception on failure.
  """
  def importaddress!(pid, address), do: importaddress!(pid, address, "")

  @doc """
  Add an address or pubkey script to the wallet without the associated private key.
  """
  def importaddress(pid, address, account), do: importaddress(pid, address, account, true)

  @doc """
  Add an address or pubkey script to the wallet without the associated private key,
  raising an exception on failure.
  """
  def importaddress!(pid, address, account), do: importaddress!(pid, address, account, true)

  @doc """
  Add an address or pubkey script to the wallet without the associated private key.
  """
  def importaddress(pid, address, account, rescan) do
    GenServer.call(pid, {:importaddress, [address, account, rescan]})
  end

  @doc """
  Add an address or pubkey script to the wallet without the associated private key,
  raising an exception on failure.
  """
  def importaddress!(pid, address, account, rescan) do
    {:ok, _} = importaddress(pid, address, account, rescan)
    :ok
  end

  @import_timeout 120_000
  @doc """
  Add a WIF private key to the wallet.
  This call times out after two minutes.
  """
  def importprivkey(pid, privkey, label) do
    GenServer.call(pid, {:importprivkey, [privkey, label]}, @import_timeout)
  end

  @doc """
  Add a WIF private key to the wallet, raising an exception on failure.
  This call times out after two minutes.
  """
  def importprivkey!(pid, privkey, label) do
    {:ok, _} = importprivkey(pid, privkey, label)
    :ok
  end

  @doc """
  Mine block immediately. Blocks are mined before RPC call returns.
  """
  def generate(pid, amount) do
    GenServer.call(pid, {:generate, [amount]})
  end

  @doc """
  Mine block immediately. Blocks are mined before RPC call returns. Raises an
  exception on failure.
  """
  def generate!(pid, amount) do
    {:ok, result} = generate(pid, amount)
    result
  end

  ##
  # Server-side
  ##
  def handle_call(request, _from, config) 
      when is_atom(request), do: handle_rpc_request(request, [], config)
  def handle_call({:importprivkey, params}, _from, config)
      when is_list(params), do: handle_rpc_request(:importprivkey, params, config, @import_timeout-100)
  def handle_call({request, params}, _from, config) 
      when is_atom(request) and is_list(params), do: handle_rpc_request(request, params, config)

  ##
  # Internal functions
  ##
  defp handle_rpc_request(method, params, config, timeout \\ 5000) when is_atom(method) do
    %Config{hostname: hostname, port: port, user: user, password: password} = config

    command = %{"jsonrpc": "2.0",
                "method": to_string(method),
                "params": params,
                "id": 1}

    headers = ["Authorization": "Basic " <> Base.encode64(user <> ":" <> password)]

    Logger.debug "Bitcoin RPC request for method: #{method}, params: #{inspect params}"

    case HTTPoison.post("http://" <> hostname <> ":" <> to_string(port) <> "/", Poison.encode!(command), headers, [{:recv_timeout, timeout}]) do
      {:ok, %{status_code: 200, body: body}} -> 
        case Poison.decode!(body) do
          %{"error" => nil, "result" => result} -> {:reply, {:ok, result}, config}
          %{"error" => error} -> {:reply, {:error, error}, config}
        end
      {:ok, %{status_code: 401}} -> 
        {:reply, :forbidden, config}
      {:ok, %{status_code: 404}} -> 
        {:reply, :notfound, config}
      {:ok, %{status_code: 500}} ->
        {:reply, :internal_server_error, config}
      otherwise -> 
        {:reply, otherwise, config}
    end
  end

  @doc """
  Converts a float BTC amount to an Decimal.
  """
  def btc_to_decimal(btc) when is_float(btc) do
    satoshi_per_btc = :math.pow(10, @satoshi_exponent)

    # Convert the bitcoins to integer to avoid any precision loss
    satoshi = round(btc * satoshi_per_btc)

    # Now construct a decimal
    %Decimal{sign: if(satoshi < 0, do: -1, else: 1), coef: abs(satoshi), exp: -@satoshi_exponent}
  end

  def btc_to_decimal(nil), do: nil
  
end

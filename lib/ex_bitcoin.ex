defmodule ExBitcoin do
  use GenServer

  require Logger

  alias ExBitcoin.Config

  @satoshi_per_btc 100000000

  ##
  # Client-side
  ##
  def start_link(config) do
    GenServer.start_link(__MODULE__, config)
  end

  def getbalance!(pid) do
    {:ok, balance} = getbalance(pid)
    balance
  end

  def getbalance(pid) do
    case GenServer.call(pid, :getbalance) do
      {:ok, balance} -> 
        {:ok, btc_to_satoshi(balance)}
      otherwise -> 
        otherwise
    end        
  end

  def getnewaddress!(pid) do
    {:ok, address} = getnewaddress(pid)
    address
  end

  def getnewaddress(pid) do
    GenServer.call(pid, :getnewaddress)
  end

  def getnewaddress!(pid, account) do
    {:ok, address} = getnewaddress(pid, account)
    address
  end

  def getnewaddress(pid, account) do
    GenServer.call(pid, {:getnewaddress, [account]})
  end

  def getaccount!(pid, address) do
    {:ok, account} = getaccount(pid, address)
    account
  end

  def getaccount(pid, address) do
    GenServer.call(pid, {:getaccount, [address]})
  end

  ##
  # Server-side
  ##
  def handle_call(request, _from, config) when is_atom(request) do
    handle_rpc_request(request, [], config)
  end

  def handle_call({request, params}, _from, config) when is_atom(request) and is_list(params) do
    handle_rpc_request(request, params, config)
  end

  ##
  # Internal functions
  ##
  defp handle_rpc_request(method, params, config) when is_atom(method) do
    %Config{hostname: hostname, port: port, user: user, password: password} = config

    command = %{"jsonrpc": "2.0",
                "method": to_string(method),
                "params": params,
                "id": 1}

    headers = ["Authorization": "Basic " <> Base.encode64(user <> ":" <> password)]

    Logger.debug "Bitcoin RPC request for method: #{method}, params: #{inspect params}"

    case HTTPoison.post("http://" <> hostname <> ":" <> to_string(port) <> "/", Poison.encode!(command), headers) do
      {:ok, %{status_code: 200, body: body}} -> 
        case Poison.decode!(body) do
          %{"error" => nil, "result" => result} -> {:reply, {:ok, result}, config}
          %{"error" => error} -> {:reply, {:error, error}, config}
        end
      {:ok, %{status_code: 401}} -> 
        {:reply, :forbidden, config}
      {:ok, %{status_code: 404}} -> 
        {:reply, :notfound, config}
      otherwise -> 
        {:reply, otherwise, config}
    end
  end

  @doc """
  Converts a float BTC amount to an integer Satoshi amount without loss of
  precision.
  """
  def btc_to_satoshi(btc) do
    round(btc * @satoshi_per_btc)
  end

  @doc """
  Converts an integer Satoshi amount to a float BTC amount. Loss of precision
  might occur.
  """
  def satoshi_to_btc(satoshi) do
    satoshi / @satoshi_per_btc
  end
  
end